local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local GetItemDefinition = require(script.Parent.GetItemDefinition)
local LocalRoundInfo = require(script.Parent.LocalRoundInfo)
local GetCentreRay = require(ReplicatedStorage.Shared.Camera.GetCentreRay)
local LocalCharacter = require(ReplicatedStorage.Shared.Character.LocalCharacter)
local ViewmodelModule = require(ReplicatedStorage.Shared.Combat.ViewmodelModule)
local ControlManager = require(ReplicatedStorage.Shared.Controls.ControlManager)
local ItemHint = require(ReplicatedStorage.Shared.Controls.ItemHint)
local ThemesManager = require(ReplicatedStorage.Shared.Interface.UILib.ThemesManager)
local UIAnimation = require(ReplicatedStorage.Shared.Interface.UILib.UIAnimation)
local UIManager = require(ReplicatedStorage.Shared.Interface.UILib.UIManager)
local ShowAlert = require(ReplicatedStorage.Shared.Interface.Util.ShowAlert)
local Types = require(ReplicatedStorage.Shared.RoundRule.Types)
local DynamicValue = require(ReplicatedStorage.Shared.Util.DynamicValue)
local ui = UIManager.WaitForUI("Inventory") :: UIManager.UI & {Object: typeof(UIManager.UnregisteredUIs.Inventory)}

local module = {}

local sampleButton = ui.Object.Sample
type ItemButton = typeof(sampleButton)

local ourInventory: {Passive: {Types.AnyItem}, Slots: {[number]: Types.AnyItem}, [number]: never} = {Passive = {}, Slots = {}}
local ourAmmo: DynamicValue.DynamicValue<{[string]: number?}> = DynamicValue.new({})

module.Inventory = ourInventory
module.EquippedItem = DynamicValue.new(nil :: Types.AnyItem?)
module.Ammo = ourAmmo

local selectedSlot: number?

local function runScheduledCallbacks(dt: number, schedulerEvent: "Heartbeat" | "PreAnimation" | "PreRender" | "PreSimulation" | "PostSimulation"): ()
	for _, v in ourInventory.Passive do
		if v.Kind == "Item" and v.Definition[schedulerEvent .. "Client"] then
			v.Definition[schedulerEvent .. "Client"](v, dt)
		end
	end

	for _, v in ourInventory.Slots do
		if v.Kind == "Item" and v.Definition[schedulerEvent .. "Client"] then
			v.Definition[schedulerEvent .. "Client"](v, dt)
		end
	end

	local item = module.EquippedItem()
	if item and item.Kind == "Gun" then
		if item.Definition[schedulerEvent .. "Client"] then
			item.Definition[schedulerEvent .. "Client"](item, dt)
		end
	end
end

RunService.Heartbeat:Connect(function(dt: number)
	runScheduledCallbacks(dt, "Heartbeat")
end)

RunService.PreAnimation:Connect(function(dt: number)
	runScheduledCallbacks(dt, "PreAnimation")
end)

RunService.PreRender:Connect(function(dt: number)
	runScheduledCallbacks(dt, "PreRender")
end)

RunService.PreSimulation:Connect(function(dt: number)
	runScheduledCallbacks(dt, "PreSimulation")
end)

RunService.PostSimulation:Connect(function(dt: number)
	runScheduledCallbacks(dt, "PostSimulation")
end)

function module.GetReserveAmmo(kind: string): number
	return module.Ammo()[kind] or 0
end

local function getNextFreeSlot(): number
	local last = 0
	for i, v in ipairs(ourInventory.Slots) do
		last = i
	end
	print(last)
	return last + 1
end

local function tryUnequip(item: Types.AnyItem, force: boolean?): boolean
	if module.EquippedItem() ~= item then
		return false
	end

	if not force and item.Definition.PreventUnequip then
		return false
	end

	selectedSlot = nil
	ItemHint()

	ControlManager.Unregister("Drop Ammo")
	ControlManager.Unregister("Drop")

	ReplicatedStorage.Remotes.ClientServer.EquipItem:FireServer(nil)

	ViewmodelModule.Hide()

	if item.Definition.OnUnequipClient then
		item.Definition.OnUnequipClient(item)
	end

	module.EquippedItem:SetValue(nil)

	local button = ui.Object.Container:FindFirstChild("Item " .. item.Definition.Name) :: ItemButton?
	if not button then
		return true
	end

	button.BackgroundTransparency = 0.75
	return true
end

local function isObscured(origin: Vector3, target: Vector3): boolean
	local char = LocalCharacter.Character()
	if not char then
		return true
	end

	local map = LocalRoundInfo.Map()
	if not map then
		return true
	end

	local params = RaycastParams.new()
	params.FilterDescendantsInstances = {char}
	params.FilterType = Enum.RaycastFilterType.Exclude

	local result = workspace:Raycast(origin, target - origin, params)
	return not not result
end

local function canDrop(direction: Vector3): boolean
	local head = LocalCharacter.Head()
	if not head then
		return false
	end

    local startPosition = head.Position + (direction * 5.5)
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

	ReplicatedStorage.Remotes.ClientServer.DropItem:FireServer(item.Definition.Name, direction)
end

local function tryDropAmmo(item: Types.GunWeapon, direction: Vector3): ()
	if not canDrop(direction) then
		return
	end

	if item.Ammo < item.Definition.AmmoType.Capacity / 4 then
		ShowAlert("You do not have enough ammo to drop an ammo box!")
		return
	end

	ReplicatedStorage.Remotes.ClientServer.DropAmmo:FireServer(item.Definition.Name, direction)
end

local function tryEquip(item: Types.AnyItem): ()
	local equippedItem = module.EquippedItem()
	if equippedItem then
		if equippedItem == item then
			return tryUnequip(item)
		end
		if not tryUnequip(equippedItem) then
			return
		end
	end

	if item.Kind == "Item" then
		ItemHint(item.Definition.PrimaryHint, item.Definition.AlternateHint)
	end

	ReplicatedStorage.Remotes.ClientServer.EquipItem:FireServer(item.Definition.Name)

	if item.Kind == "Gun" and item.Definition.AmmoType.CanDrop then
		ControlManager.Register("Drop Ammo", function(_, state)
			if state ~= Enum.UserInputState.End then
				return Enum.ContextActionResult.Pass
			end

			tryDropAmmo(item, GetCentreRay().Direction)
			return Enum.ContextActionResult.Sink
		end)
	end

	if item.Definition.CanDrop and not item.Definition.PreventUnequip then
		ControlManager.Register("Drop", function(_, state)
			if state ~= Enum.UserInputState.End then
				return Enum.ContextActionResult.Pass
			end

			tryDropItem(item, GetCentreRay().Direction)
			return Enum.ContextActionResult.Sink
		end)
	end

	ViewmodelModule.Show(item.Definition)

	if item.Definition.OnEquipClient then
		item.Definition.OnEquipClient(item)
	end

	module.EquippedItem:SetValue(item)

	selectedSlot = nil

	local button = ui.Object.Container:FindFirstChild("Item " .. item.Definition.Name) :: ItemButton?
	if not button then
		return
	end

	selectedSlot = button.LayoutOrder
	button.BackgroundTransparency = 0.25
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

local function tryAddButton(item: Types.AnyItem, slot: number): ()
	local gamemode = LocalRoundInfo.Gamemode()
	if not gamemode then
		return
	end

	local clone = sampleButton:Clone()
	clone.Text = item.Definition.DisplayName or item.Definition.Name
	clone.TextLabel.Text = `[{slot}]`
	clone.LayoutOrder = slot

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
	local equippedItem = module.EquippedItem()
	if equippedItem and equippedItem.Definition.Name == itemName then
		tryUnequip(equippedItem, true)
	end

	local slot: number?
	for i, v in ourInventory.Slots do
		if v.Definition.Name == itemName then
			slot = i
			break
		end
	end

	if not slot then
		for i, v in ourInventory.Passive do
			if v.Definition.Name == itemName then
				table.remove(ourInventory.Passive, i)
				if v.Definition.OnUnequipClient then
					v.Definition.OnUnequipClient(v)
				end
				return
			end
		end
		return
	end

	tryRemoveButton(itemName)
	ourInventory.Slots[slot] = nil
end

local function addItem(item: Types.AnyItem): ()
	(item :: {Definition: Types.AnyItemDefinition}).Definition = assert(GetItemDefinition(item.Definition.Name), "Item exists on server but not client")

	local gamemode = LocalRoundInfo.Gamemode()
	if not gamemode then
		return
	end

	local slot = if gamemode.IsSlotless then getNextFreeSlot() else item.Definition.ItemGroup and item.Definition.ItemGroup.PreferredSlot
	if slot then
		if ourInventory.Slots[slot] then
			slot = getNextFreeSlot()
		end
		tryAddButton(item, slot)
		ourInventory.Slots[slot] = item
		return
	end

	table.insert(ourInventory.Passive, item)
	if item.Definition.OnEquipClient then
		item.Definition.OnEquipClient(item)
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
	local equippedItem = module.EquippedItem()
	if not equippedItem then
		return selectLowest()
	end

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

ReplicatedStorage.Shared.RoundRule.Remotes.UpdateInventory.OnClientEvent:Connect(function(mode: "Add" | "Remove" | "Reset", item: string | Types.AnyItem?): ()
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

ReplicatedStorage.Shared.RoundRule.Remotes.UpdateReserveAmmo.OnClientEvent:Connect(function(mode: "Update" | "Reset", kind: string?, amount: number?): ()
	if mode == "Update" then
		assert(typeof(kind) == "string", "Kind must be a string")
		assert(typeof(amount) == "number", "Amount must be a number")

		module.Ammo()[kind] = amount
		module.Ammo:Invoke()
	elseif mode == "Reset" then
		assert(typeof(kind) == "nil", "Kind must be nil")
		module.Ammo:SetValue({})
	else
		error("Invalid mode")
	end
end)

ReplicatedStorage.Remotes.ClientServer.ReloadWeapon.OnClientEvent:Connect(function(itemName: string, amount: number): ()
	for _, v in ourInventory.Slots do
		if v.Definition.Name == itemName then
			assert(v.Kind == "Gun", "Item is not a gun")
			v.IsReloading = false
			v.Ammo = amount
			module.Ammo:Invoke()
		end
	end
end)

ReplicatedStorage.Remotes.ServerClient.UpdateAmmo.OnClientEvent:Connect(function(itemName: string, amount: number): ()
	for _, v in ourInventory.Slots do
		if v.Definition.Name == itemName then
			assert(v.Kind == "Gun", "Item is not a gun")
			v.Ammo = amount
			module.Ammo:Invoke()
		end
	end
end)

StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)

return module