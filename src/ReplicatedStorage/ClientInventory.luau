local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local ControlManager = require(script.Parent.ControlManager)
local GetItemDefinition = require(script.Parent.GetItemDefinition)
local ThemesManager = require(script.Parent.ThemesManager)
local UIAnimation = require(script.Parent.UIAnimation)
local Types = require(ReplicatedStorage.RoundRule.Types)
local UIManager = require(script.Parent.UIManager)
local ViewmodelModule = require(script.Parent.ViewmodelModule)
local ui = UIManager.WaitForUI("Inventory") :: UIManager.UI & {Object: typeof(UIManager.UnregisteredUIs.Inventory)}

local module = {}

local sampleButton = ui.Object.Sample
type ItemButton = typeof(sampleButton)

local ourInventory: {Passive: {Types.AnyItem}, Slots: {[number]: Types.AnyItem}} = {Passive = {}, Slots = {}}

module.EquippedItem = nil :: Types.AnyItem?

local itemChangedConnections: {(item: Types.AnyItem?) -> ()} = {}
function module.ConnectEquippedItemChanged(callback: (item: Types.AnyItem?) -> ()): ()
	table.insert(itemChangedConnections, callback)
end

local function runCallbacks(): ()
	for _, v in itemChangedConnections do
		task.spawn(v, module.EquippedItem)
	end
end

local function tryUnequip(item: Types.AnyItem): ()
	if module.EquippedItem ~= item then
		return
	end

	module.EquippedItem = nil

	runCallbacks()

	ReplicatedStorage.ClientServer.EquipItem:FireServer(nil)

	local button = ui.Object.Container:FindFirstChild("Item " .. item.Definition.Name) :: ItemButton?
	if not button then
		return
	end

	button.BackgroundTransparency = 0.75

	ViewmodelModule.Hide()
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

	ControlManager.Register("Drop", true, function(_, state)
		if state ~= Enum.UserInputState.End then
			return Enum.ContextActionResult.Pass
		end

		ReplicatedStorage.ClientServer.DropWeapon:FireServer(item.Definition.Name)
		return Enum.ContextActionResult.Sink
	end)

	runCallbacks()

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
	clone.Parent = ui.Object.Container

	ourInventory.Slots[item.Definition.Slot] = item
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
	tryAddButton(item)
	table.insert(ourInventory, item)
end

for i = 1, 9 do
	ControlManager.Register("Slot " .. i, false, function()
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

ControlManager.Register("Next Weapon", false, function()
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

ReplicatedStorage.RoundRule.Remotes.UpdateInventory.OnClientEvent:Connect(function(mode: "Add" | "Remove" | "Reset", item: string | Types.AnyItem): ()
	if mode == "Add" then
		assert(typeof(item) == "table", "Item must be a table")
		addItem(item)
	elseif mode == "Remove" then
		assert(typeof(item) == "string", "Item must be a string")
		removeItem(item)
	elseif mode == "Reset" then
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

StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)

return module