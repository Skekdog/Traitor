local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local ControlManager = require(script.Parent.ControlManager)
local GetCentreRay = require(script.Parent.GetCentreRay)
local GetItemDefinition = require(script.Parent.GetItemDefinition)
local LocalCharacter = require(script.Parent.LocalCharacter)
local LocalRoundInfo = require(script.Parent.LocalRoundInfo)
local ShowAlert = require(script.Parent.ShowAlert)
local ThemesManager = require(script.Parent.ThemesManager)
local UIAnimation = require(script.Parent.UIAnimation)
local Types = require(ReplicatedStorage.RoundRule.Types)
local UIManager = require(script.Parent.UIManager)
local ViewmodelModule = require(script.Parent.ViewmodelModule)
local ui = UIManager.WaitForUI("Inventory") :: UIManager.UI & {Object: typeof(UIManager.UnregisteredUIs.Inventory)}

local module = {}

local sampleButton = ui.Object.Sample
type ItemButton = typeof(sampleButton)

export type AmmoCallback = (amount: number?) -> ()
export type AmmoConnection = {Kind: string, Callback: AmmoCallback}

local ourInventory: {Passive: {Types.AnyItem}, Slots: {[number]: Types.AnyItem}, [number]: never} = {Passive = {}, Slots = {}}
local ourAmmo: {[string]: number?} = {}

module.EquippedItem = nil :: Types.AnyItem?
module.Ammo = ourAmmo

local itemChangedConnections: {(item: Types.AnyItem?) -> ()} = {}
function module.ConnectEquippedItemChanged(callback: (item: Types.AnyItem?) -> ()): ()
	table.insert(itemChangedConnections, callback)
end

RunService.Heartbeat:Connect(function(dt)
	for _, v in ourInventory.Passive do
		if v.Kind == "Item" and v.Definition.HeartbeatClient then
			v.Definition.HeartbeatClient(v, dt)
		end
	end

	for _, v in ourInventory.Slots do
		if v.Kind == "Item" and v.Definition.HeartbeatClient then
			v.Definition.HeartbeatClient(v, dt)
		end
	end
end)

local ammoChangedConnections: {AmmoConnection} = {}
function module.ConnectAmmoChanged(kind: string, callback: AmmoCallback): ()
	local st = {Kind = kind, Callback = callback}
	table.insert(ammoChangedConnections, st)
	return st
end

function module.RemoveAmmoChangedConnection(connection: AmmoConnection): ()
	local index = table.find(ammoChangedConnections, connection)
	if index then
		table.remove(ammoChangedConnections, index)
	end
end

function module.GetReserveAmmo(kind: string): number
	return module.Ammo[kind] or 0
end

local function runAmmoChangedCallbacks(): ()
	for _, v in ammoChangedConnections do
		task.spawn(v.Callback, module.Ammo[v.Kind])
	end
end

local function runItemChangedCallbacks(): ()
	for _, v in itemChangedConnections do
		task.spawn(v, module.EquippedItem)
	end
	runAmmoChangedCallbacks()
end

local function tryUnequip(item: Types.AnyItem): ()
	if module.EquippedItem ~= item then
		return
	end

	ControlManager.Unregister("Drop Ammo")
	ControlManager.Unregister("Drop")

	module.EquippedItem = nil

	runItemChangedCallbacks()

	ReplicatedStorage.ClientServer.EquipItem:FireServer(nil)

	local button = ui.Object.Container:FindFirstChild("Item " .. item.Definition.Name) :: ItemButton?
	if not button then
		return
	end

	button.BackgroundTransparency = 0.75

	ViewmodelModule.Hide()
end

local function isObscured(origin: Vector3, target: Vector3): boolean
	local char = LocalCharacter.GetCharacter()
	if not char then
		return true
	end

	local map = LocalRoundInfo.GetMap()
	if not map then
		return true
	end

	local params = RaycastParams.new()
	params.FilterDescendantsInstances = {char, map.Bounds}
	params.FilterType = Enum.RaycastFilterType.Exclude

	local result = workspace:Raycast(origin, target - origin, params)
	return not not result
end

local function canDrop(direction: Vector3): boolean
	local head = LocalCharacter.GetHead()
	if not head then
		return false
	end

	local velocityModifier = head.AssemblyLinearVelocity:Dot(direction) / (16 * 3)
    local startPosition = head.Position + (direction * 3) + (head.AssemblyLinearVelocity * velocityModifier)
	if isObscured(head.Position, startPosition) then
		ShowAlert("There is no room to drop anything here!")
		return false
	end

	return true
end

local function tryDropItem(item: Types.AnyItem, direction: Vector3): ()
	if not canDrop(direction) then
		return
	end

	ReplicatedStorage.ClientServer.DropItem:FireServer(item.Definition.Name, direction)
end

local function tryDropAmmo(item: Types.GunWeapon, direction: Vector3): ()
	if not canDrop(direction) then
		return
	end

	if item.Ammo < item.Definition.AmmoType.Capacity / 4 then
		ShowAlert("You do not have enough ammo to drop an ammo box!")
		return
	end

	ReplicatedStorage.ClientServer.DropAmmo:FireServer(item.Definition.Name, direction)
end

local function tryEquip(item: Types.AnyItem): ()
	if module.EquippedItem then
		if module.EquippedItem == item then
			return tryUnequip(item)
		end
		tryUnequip(module.EquippedItem)
	end

	local button = ui.Object.Container:FindFirstChild("Item " .. item.Definition.Name) :: ItemButton?
	if not button then
		return
	end

	button.BackgroundTransparency = 0.25
	module.EquippedItem = item

	ReplicatedStorage.ClientServer.EquipItem:FireServer(item.Definition.Name)

	if item.Kind == "Gun" and item.Definition.AmmoType.CanDrop then
		ControlManager.Register("Drop Ammo", function(_, state)
			if state ~= Enum.UserInputState.End then
				return Enum.ContextActionResult.Pass
			end

			tryDropAmmo(item, GetCentreRay().Direction)
			return Enum.ContextActionResult.Sink
		end)
	end

	if item.Definition.CanDrop then
		ControlManager.Register("Drop", function(_, state)
			if state ~= Enum.UserInputState.End then
				return Enum.ContextActionResult.Pass
			end

			tryDropItem(item, GetCentreRay().Direction)
			return Enum.ContextActionResult.Sink
		end)
	end

	runItemChangedCallbacks()

	ViewmodelModule.Show(item.Definition)
end

local INV_BUTTON_SIZE = 0.065
local INV_BUTTON_PADDING = 25
local function move(clone: typeof(sampleButton), order: number, middle: number): ()
	local difference = order - middle
	local mult = if difference < 0 then -1 else 1
	
	local relativePosition
	if order == middle then
		relativePosition = UDim2.new()
	else
		local padding = INV_BUTTON_PADDING * mult
		local sizeMult = 1.5
		if (order == middle - 0.5) or (order == middle + 0.5) then
			sizeMult = 1.25
			padding /= 2
		end
		relativePosition = UDim2.new((INV_BUTTON_SIZE * sizeMult * difference), padding, 0, 0)
	end

	UIAnimation.Animate(clone, TweenInfo.new(0.2), {Position = UDim2.fromScale(0.5, 0) + relativePosition})
end

local function tryAddButton(item: Types.AnyItem): ()
	if not item.Definition.Slot then
		return
	end

	local clone = sampleButton:Clone()
	clone.Text = item.Definition.DisplayName or item.Definition.Name
	clone.TextLabel.Text = `[{item.Definition.Slot}]`
	clone.LayoutOrder = item.Definition.Slot

	clone.Position = UDim2.fromScale(0.5, 1.2)
	clone.Visible = true

	ThemesManager.UpdateThemeInstance(clone, nil, true)
	ThemesManager.UpdateThemeInstance(clone.TextLabel, nil, true)

	clone.Name = "Item " .. item.Definition.Name
	clone.Parent = ui.Object.Container :: any

	clone.MouseButton1Click:Connect(function()
		tryEquip(item)
	end)

	local buttons = ui.Object.Container:GetChildren() :: {any} -- trying to use {TextButton} errors, presumably because reasons
	table.sort(buttons, function(a, b)
		return a.LayoutOrder < b.LayoutOrder
	end)

	for _, v in buttons do
		move(v, table.find(buttons, v) :: number, (#buttons + 1) / 2)
	end
end

local function tryRemoveButton(itemName: string)
	local found = ui.Object.Container:FindFirstChild("Item " .. itemName) :: ItemButton?
	local buttons = (ui.Object.Container:GetChildren() :: {any}) :: {ItemButton}

	if found then
		found.Parent = ui.Object
		table.remove(buttons, table.find(buttons, found))
		
		local tween = UIAnimation.Animate(found, TweenInfo.new(0.2), {
			Position = UDim2.fromScale(0.5, 1.2)
		})

		if tween then
			tween.Completed:Once(function()
				found:Destroy()
			end)
		else
			found:Destroy()
		end
	end

	table.sort(buttons, function(a, b)
		return a.LayoutOrder < b.LayoutOrder
	end)

	for _, v in buttons do
		move(v, table.find(buttons, v) :: number, (#buttons + 1) / 2)
	end
end

local function removeItem(itemName: string): ()
	if module.EquippedItem and module.EquippedItem.Definition.Name == itemName then
		tryUnequip(module.EquippedItem)
	end
	
	local item = GetItemDefinition(itemName)
	if not item then
		return
	end

	if not item.Slot then
		for i, v in ourInventory.Passive do
			if v.Definition.Name == itemName then
				table.remove(ourInventory.Passive, i)
				return
			end
		end
		return
	end

	tryRemoveButton(itemName)
	ourInventory.Slots[item.Slot] = nil
end

local function addItem(item: Types.AnyItem): ()
	(item :: {Definition: Types.AnyItemDefinition}).Definition = assert(GetItemDefinition(item.Definition.Name), "Item exists on server but not client")
	tryAddButton(item)
	
	if item.Definition.Slot then
		ourInventory.Slots[item.Definition.Slot] = item
	else
		table.insert(ourInventory.Passive, item)
	end
end

for i = 1, 9 do
	ControlManager.Register("Slot " .. i, function()
		local item = ourInventory.Slots[i]
		if item then
			tryEquip(item)
			return Enum.ContextActionResult.Sink
		end
		return Enum.ContextActionResult.Pass
	end)
end

local function getMinIndex(tbl: {[number]: any}): number
    -- note: the order of non-sequential table keys is undefined
    local lowest = table.maxn(tbl :: {any})
    for i in tbl do
        if i < lowest then
            lowest = i :: number
        end
    end

    return lowest
end

local function selectLowest()
	local lowest = getMinIndex(ourInventory.Slots)
	if lowest == 0 then
		return Enum.ContextActionResult.Pass
	end
	tryEquip(ourInventory.Slots[lowest])
	return Enum.ContextActionResult.Sink
end

ControlManager.Register("Next Item", function()
	if not module.EquippedItem then
		return selectLowest()
	end

	local selectedSlot = module.EquippedItem.Definition.Slot
	if not selectedSlot then
		return Enum.ContextActionResult.Pass
	end

	if selectedSlot + 1 > table.maxn(ourInventory.Slots) then
		return selectLowest()
	end

	if table.maxn(ourInventory.Slots) == selectedSlot then
		tryUnequip(ourInventory.Slots[selectedSlot])
		return Enum.ContextActionResult.Sink
	end

	for i = selectedSlot + 1, 9 do
		if ourInventory.Slots[i] then
			tryEquip(ourInventory.Slots[i])
			return Enum.ContextActionResult.Sink
		end
	end

	return Enum.ContextActionResult.Pass
end)

ReplicatedStorage.RoundRule.Remotes.UpdateInventory.OnClientEvent:Connect(function(mode: "Add" | "Remove" | "Reset", item: string | Types.AnyItem?): ()
	if mode == "Add" then
		assert(typeof(item) == "table", "Item must be a table")
		addItem(item)
	elseif mode == "Remove" then
		assert(typeof(item) == "string", "Item must be a string")
		removeItem(item)
	elseif mode == "Reset" then
		assert(typeof(item) == "nil", "Item must be nil")
		for _, v in ourInventory.Passive do
			removeItem(v.Definition.Name)
		end

		for _, v in ourInventory.Slots do
			removeItem(v.Definition.Name)
		end
	else
		error("Invalid mode")
	end
end)

ReplicatedStorage.RoundRule.Remotes.UpdateReserveAmmo.OnClientEvent:Connect(function(mode: "Update" | "Reset", kind: string?, amount: number?): ()
	if mode == "Update" then
		assert(typeof(kind) == "string", "Kind must be a string")
		assert(typeof(amount) == "number", "Amount must be a number")
		module.Ammo[kind] = amount
		runAmmoChangedCallbacks()
	elseif mode == "Reset" then
		assert(typeof(kind) == "nil", "Kind must be nil")
		module.Ammo = {}
		runAmmoChangedCallbacks()
	else
		error("Invalid mode")
	end
end)

ReplicatedStorage.ClientServer.ReloadWeapon.OnClientEvent:Connect(function(itemName: string, amount: number): ()
	for _, v in ourInventory.Slots do
		if v.Definition.Name == itemName then
			assert(v.Kind == "Gun", "Item is not a gun")
			v.IsReloading = false
			v.Ammo = amount
			runAmmoChangedCallbacks()
		end
	end
end)

ReplicatedStorage.ServerClient.UpdateAmmo.OnClientEvent:Connect(function(itemName: string, amount: number): ()
	for _, v in ourInventory.Slots do
		if v.Definition.Name == itemName then
			assert(v.Kind == "Gun", "Item is not a gun")
			v.Ammo = amount
			runAmmoChangedCallbacks()
		end
	end
end)

StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)

return module