local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local Camera = require(ReplicatedStorage.API.Camera)
local GetItemDefinition = require(script.Parent.GetItemDefinition)
local LocalRoundInfo = require(script.Parent.LocalRoundInfo)
local GetCentreRay = require(ReplicatedStorage.Shared.Camera.GetCentreRay)
local LocalCharacter = require(ReplicatedStorage.Shared.Character.LocalCharacter)
local Viewmodel = require(ReplicatedStorage.Shared.Combat.Viewmodel)
local ControlManager = require(ReplicatedStorage.Shared.Controls.ControlManager)
local ItemHint = require(ReplicatedStorage.Shared.Controls.ItemHint)
local ThemesManager = require(ReplicatedStorage.Shared.Interface.UILib.ThemesManager)
local UIManager = require(ReplicatedStorage.Shared.Interface.UILib.UIManager)
local ShowAlert = require(ReplicatedStorage.Shared.Interface.Util.ShowAlert)
local Item = require(ReplicatedStorage.Shared.RoundRule.Item)
local Types = require(ReplicatedStorage.API.Types)
local DynamicValue = require(ReplicatedStorage.Shared.Util.DynamicValue)

local ui = UIManager.WaitForUI("Inventory") :: UIManager.UI & {Object: typeof(UIManager.UnregisteredUIs.Inventory)}
local inventoryButtonUi = UIManager.WaitForUI("InventoryButton") :: UIManager.UI & {Object: typeof(UIManager.UnregisteredUIs.InventoryButton)}

local module = {}

local sampleButton = ui.Object.ButtonTemplate
type ItemButton = typeof(sampleButton)

local ourInventory: {Passive: {Types.Item}, Slots: DynamicValue.DynamicValue<{[number]: Types.Item}>, [number]: never} = {Passive = {}, Slots = DynamicValue.new({})}
local ourAmmo: DynamicValue.DynamicValue<{[string]: number?}> = DynamicValue.new({})

module.Inventory = ourInventory
module.EquippedItem = DynamicValue.new(nil :: Types.Item?)
module.Ammo = ourAmmo

local selectedSlot: number?

local function runScheduledCallbacks(dt: number, schedulerEvent: "Heartbeat" | "PreAnimation" | "PreRender" | "PreSimulation" | "PostSimulation"): ()
	for _, v in ourInventory.Passive do
		if v[schedulerEvent .. "Client"] then
			v[schedulerEvent .. "Client"](v, dt)
		end
	end

	local equippedItem = module.EquippedItem()
	if equippedItem and equippedItem[schedulerEvent .. "Client"] then
		equippedItem[schedulerEvent .. "Client"](equippedItem, dt)
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
	for i, v in ipairs(ourInventory.Slots()) do
		last = i
	end
	return last + 1
end

local function tryUnequip(item: Types.Item, force: boolean?): boolean
	if module.EquippedItem() ~= item then
		return false
	end

	if not force and item.UnequipDisabled then
		return false
	end

	selectedSlot = nil
	ItemHint()

	ControlManager.Unregister("Drop Ammo")
	ControlManager.Unregister("Drop")

	ReplicatedStorage.Remotes.ClientServer.EquipItem:FireServer(nil)

	Viewmodel.Hide()

	if item.OnUnequipClient then
		item.OnUnequipClient(item)
	end

	module.EquippedItem:SetValue(nil)

	local button = ui.Object:FindFirstChild("Item " .. item.Name) :: ItemButton?
	if not button then
		return true
	end

	button.BackgroundTransparency = 0.7
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
	params.ExcludeInstances = {char}

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

local function tryDropItem(item: Types.Item, direction: Vector3): ()
	if item.DropDisabled then
		return
	end

	if not canDrop(direction) then
		return
	end

	ReplicatedStorage.Remotes.ClientServer.DropItem:FireServer(item.Name, direction)
end

local function tryDropAmmo(item: Types.Item, direction: Vector3): ()
	if not canDrop(direction) then
		return
	end

	if not item.Ammo or not item.AmmoDefinition then
		return
	end

	if item.Ammo < item.AmmoDefinition.Capacity / 4 then
		ShowAlert("You do not have enough ammo to drop an ammo box!")
		return
	end

	ReplicatedStorage.Remotes.ClientServer.DropAmmo:FireServer(item.Name, direction)
end

local function tryEquip(item: Types.Item): ()
	local char = LocalCharacter.Character()
	if char and char:GetAttribute("IsRagdolled") then
		return
	end

	local equippedItem = module.EquippedItem()
	if equippedItem then
		if equippedItem == item then
			return tryUnequip(item)
		end
		if not tryUnequip(equippedItem) then
			return
		end
	end

	ItemHint(item.PrimaryHint, item.AlternateHint)

	ReplicatedStorage.Remotes.ClientServer.EquipItem:FireServer(item.Name)

	if item.AmmoDefinition and item.AmmoDefinition.CanDrop then
		ControlManager.Register("Drop Ammo", function(_, state)
			tryDropAmmo(item, GetCentreRay(nil, Camera.IsFirstPerson()).Direction)
			return Enum.ContextActionResult.Pass
		end)
	end

	if not item.DropDisabled and not item.UnequipDisabled then
		ControlManager.Register("Drop", function(_, state)
			tryDropItem(item, GetCentreRay(nil, Camera.IsFirstPerson()).Direction)
			return Enum.ContextActionResult.Pass
		end)
	end

	Viewmodel.Show(item)

	if item.OnEquipClient then
		item.OnEquipClient(item)
	end

	module.EquippedItem:SetValue(item)

	selectedSlot = nil

	local button = ui.Object:FindFirstChild("Item " .. item.Name) :: ItemButton?
	if not button then
		return
	end

	selectedSlot = button.LayoutOrder
	button.BackgroundTransparency = 0.3
end

local function tryAddButton(item: Types.Item, slot: number): ()
	local gamemode = LocalRoundInfo.Gamemode()
	if not gamemode then
		return
	end

	local clone = sampleButton:Clone()
	clone.TextLabel.Text = item.DisplayName or item.Name
	clone.LayoutOrder = slot

	clone:SetAttribute("Control", "Slot " .. slot)
	clone:AddTag("ControlHint")

	clone.Position = UDim2.fromScale(0.5, 1.2)
	clone.Visible = true

	ThemesManager.UpdateThemeInstance(clone, nil, true)
	ThemesManager.UpdateThemeInstance(clone.TextLabel, nil, true)

	clone.Name = "Item " .. item.Name
	clone.Parent = ui.Object :: any

	clone.Activated:Connect(function()
		if ControlManager.PreferredInput() == Enum.PreferredInput.Touch or ControlManager.PreferredInput() == Enum.PreferredInput.Gamepad then
			ui:ToggleVisible(false)
		end
		tryEquip(item)
	end)
end

local function tryRemoveButton(itemName: string)
	local found = ui.Object:FindFirstChild("Item " .. itemName) :: ItemButton?
	if found then
		found:Destroy()
	end
end

local function removeItem(itemName: string): ()
	local equippedItem = module.EquippedItem()
	if equippedItem and equippedItem.Name == itemName then
		tryUnequip(equippedItem, true)
	end

	local slot: number?
	for i, v in ourInventory.Slots() do
		if v.Name == itemName then
			slot = i
			break
		end
	end

	if not slot then
		for i, v in ourInventory.Passive do
			if v.Name == itemName then
				table.remove(ourInventory.Passive, i)
				if v.OnUnequipClient then
					v.OnUnequipClient(v)
				end
				return
			end
		end
		return
	end

	tryRemoveButton(itemName)
	ourInventory.Slots()[slot] = nil
	ourInventory.Slots:Invoke()
end

function module.RemoveItem(item: Types.Item): ()
	removeItem(item.Name)
end

function module.CreateReplicatedItem(replicate: Types.ItemReplication): Types.Item
	local base = assert(GetItemDefinition(replicate.Name), "Item exists on server but not client")

	local item = Item.new(base, replicate.Model)
	item.Components = replicate.Components

	return item
end

function module.GetItem(itemName: string): Types.Item?
	for i, v in ourInventory.Slots() do
		if v.Name == itemName then
			return v
		end
	end

	for i, v in ourInventory.Passive do
		if v.Name == itemName then
			return v
		end
	end

	return nil
end

local function addItem(replicate: Types.ItemReplication): ()
	local item = module.CreateReplicatedItem(replicate)

	local gamemode = LocalRoundInfo.Gamemode()
	if not gamemode then
		return
	end

	local slot = if gamemode.IsSlotless then getNextFreeSlot() else item.ItemGroup and item.ItemGroup.PreferredSlot
	if slot then
		if ourInventory.Slots()[slot] then
			slot = getNextFreeSlot()
		end
		tryAddButton(item, slot)
		ourInventory.Slots()[slot] = item
		ourInventory.Slots:Invoke()
		return
	end

	table.insert(ourInventory.Passive, item)
	if item.OnEquipClient then
		item.OnEquipClient(item)
	end
end

for i = 1, 9 do
	ControlManager.Register("Slot " .. i, function()
		local item = ourInventory.Slots()[i]
		if item then
			tryEquip(item)
			return Enum.ContextActionResult.Pass
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
	local lowest = getMinIndex(ourInventory.Slots())
	if lowest == 0 then
		return Enum.ContextActionResult.Pass
	end
	tryEquip(ourInventory.Slots()[lowest])
	return Enum.ContextActionResult.Pass
end

ControlManager.Register("Next Item", function()
	local equippedItem = module.EquippedItem()
	if not equippedItem then
		return selectLowest()
	end

	if not selectedSlot then
		return Enum.ContextActionResult.Pass
	end

	if selectedSlot + 1 > table.maxn(ourInventory.Slots()) then
		return selectLowest()
	end

	if table.maxn(ourInventory.Slots()) == selectedSlot then
		tryUnequip(ourInventory.Slots()[selectedSlot])
		return Enum.ContextActionResult.Pass
	end

	for i = selectedSlot + 1, 9 do
		if ourInventory.Slots()[i] then
			tryEquip(ourInventory.Slots()[i])
			return Enum.ContextActionResult.Pass
		end
	end

	return Enum.ContextActionResult.Pass
end)

ReplicatedStorage.Shared.RoundRule.Remotes.UpdateInventory.OnClientEvent:Connect(function(mode: "Add" | "Remove" | "Reset", item: string | Types.ItemReplication?): ()
	if mode == "Add" then
		assert(typeof(item) == "table")
		addItem(item)
	elseif mode == "Remove" then
		assert(typeof(item) == "string")
		removeItem(item)
	elseif mode == "Reset" then
		for _, v in ourInventory.Passive do
			removeItem(v.Name)
		end

		for _, v in ourInventory.Slots() do
			removeItem(v.Name)
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

ReplicatedStorage.Shared.RoundRule.Remotes.SetEquippedItem.OnClientEvent:Connect(function(itemName: string?): ()
	if not itemName then
		local equippedItem = module.EquippedItem()
		if equippedItem then
			return tryUnequip(equippedItem)
		end
		return
	end

	local item: Types.Item?
	for _, v in ourInventory.Slots() do
		if v.Name == itemName then
			item = v
			break
		end
	end

	if item and item ~= module.EquippedItem() then
		tryEquip(item)
	end
end)

ReplicatedStorage.Remotes.ClientServer.ReloadWeapon.OnClientEvent:Connect(function(itemName: string, amount: number): ()
	for _, v in ourInventory.Slots() do
		if v.Name == itemName then
			v.IsReloading = false
			v.Ammo = amount
			module.Ammo:Invoke()
		end
	end
end)

ReplicatedStorage.Remotes.ServerClient.UpdateAmmo.OnClientEvent:Connect(function(itemName: string, amount: number): ()
	for _, v in ourInventory.Slots() do
		if v.Name == itemName then
			v.Ammo = amount
			module.Ammo:Invoke()
		end
	end
end)

ControlManager.PreferredInput:Connect(function(preferredInput)
	local isTouch = preferredInput == Enum.PreferredInput.Touch
	local isGamepad = preferredInput == Enum.PreferredInput.Gamepad

	local isTouchOrGamepad = isTouch or isGamepad

	ui:ToggleVisible(false, nil, function()
		ui.Object.AnchorPoint = if isTouchOrGamepad then Vector2.one / 2 else Vector2.one
	end)

	ui.Object:SetAttribute("TransitionDirection", if isTouchOrGamepad then "Up" else "Left")
	ui.Object:SetAttribute("TransitionTarget", if isTouchOrGamepad then UDim2.new(0.5, 0, 0.5, 0) else UDim2.new(1, -10, 1, -10))

	if not isTouchOrGamepad then
		ui:ToggleVisible(true)
	end

	inventoryButtonUi:ToggleVisible(isTouch)
end, true)

inventoryButtonUi.Object.Activated:Connect(function()
	ui:ToggleVisible()
end)

StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)

return table.freeze(module)