local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local Types = require(ReplicatedStorage.RoundRule.Types)
local UIManager = require(script.Parent.Parent)
local ThemesManager = require(script.Parent.Parent.Parent.ThemesManager)
local UIAnimation = require(script.Parent.Parent.Parent.UIAnimation)

local backpack = UIManager.WaitForUI("Backpack").Object :: typeof(UIManager.UnregisteredUIs.Backpack)

local sample = backpack.Sample
sample.Parent = nil -- so that it doesn't get counted for animation

local selectedItem: Types.AnyItem?

local function unequip(equipment: Types.AnyItem): ()
	local found = backpack.Container:FindFirstChild(equipment.Definition.Name) :: TextButton
	if found then
		found.BackgroundTransparency = 0.75
	end
	InventoryManager.Unequip(equipment)
	selectedItem = nil
end

-- Surely there is a better way to do this
local function switchToEquipment(equipment: Types.AnyItem?)
	if equipment then
		if equipment == selectedItem then
			unequip(equipment)
			return Enum.ContextActionResult.Sink
		else
			InventoryManager.Equip(equipment)
			local found = backpack.Container:FindFirstChild(equipment.Base.Name) :: TextButton
			if found then
				found.BackgroundTransparency = 0.25
			end

			if selectedItem then
				unequip(selectedItem)
			end
		end
	elseif selectedItem then
		unequip(selectedItem)
	end
	selectedItem = equipment
	return Enum.ContextActionResult.Sink
end

local INV_BUTTON_SIZE = 0.065
local INV_BUTTON_PADDING = 25
local function move(clone: typeof(sample), order: number, middle: number): ()
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

local slots: {[number]: Types.AnyItem?} = {}
local function add(equipmentName: string, params: ItemTypes.ClientItemInitParams?): ()
	local equipment = InventoryManager.AddEquipment(equipmentName, params)

	local clone = sample:Clone()
	clone.Text = equipment.Base.Name
	clone.TextLabel.Text = `[{equipment.Base.Slot}]`
	clone.LayoutOrder = equipment.Base.Slot

	clone.Position = UDim2.fromScale(0.5, 1.2)
	clone.Visible = true

	ThemesManager.UpdateThemeInstance(clone, nil, true)
	ThemesManager.UpdateThemeInstance(clone.TextLabel, nil, true)

	clone.Name = equipment.Base.Name
	clone.Parent = backpack.Container

	slots[equipment.Base.Slot] = equipment
	clone.MouseButton1Click:Connect(function()
		switchToEquipment(equipment)
	end)

	local buttons = backpack.Container:GetChildren() :: {any} -- trying to use {TextButton} errors, presumably because reasons
	table.sort(buttons, function(a, b)
		return a.LayoutOrder < b.LayoutOrder
	end)

	for _, v in buttons do
		move(v, table.find(buttons, v) :: number, (#buttons + 1) / 2)
	end
end

local function remove(equipmentName: string)
	local equipment = InventoryManager.Items[equipmentName]
	if not equipment then
		return
	end
	InventoryManager.RemoveEquipment(equipment)

	local found = backpack.Container:FindFirstChild(equipment.Base.Name)
	local buttons = backpack.Container:GetChildren() :: {any}

	if found then
		found.Parent = backpack
		slots[equipment.Base.Slot] = nil
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

	if selectedItem and equipment.Base.Name == selectedItem.Base.Name then
		selectedItem = nil
	end

	table.sort(buttons, function(a, b)
		return a.LayoutOrder < b.LayoutOrder
	end)

	for _, v in buttons do
		move(v, table.find(buttons, v) :: number, (#buttons + 1) / 2)
	end
end

InventoryManager.InvEvent.OnClientEvent:Connect(function(event: InventoryManager.InventoryEvent, equipment: string?, params: ItemTypes.ClientItemInitParams?)
	if not equipment then
		return
	end
	if event == "Add" then
		add(equipment, params)
	elseif event == "Remove" then
		remove(equipment)
	elseif event == "Unequip" then
		if selectedItem and Items[equipment].Name == selectedItem.Base.Name then
			selectedItem = nil
		end
	end
end)

for i = 1, 9 do
	ControlManager.Register("Slot "..i, false, function()
		local equipment = slots[i]
		if equipment then
			switchToEquipment(equipment)
			return Enum.ContextActionResult.Sink
		end
		return Enum.ContextActionResult.Pass
	end)
end

local function minN(table: {any}): number?
	for i in table do
		if table[i] then
			return i
		end
	end
	return
end

do
	local function selectLowest()
		local lowest = minN(slots)
		if not lowest then
			return Enum.ContextActionResult.Pass
		end
		switchToEquipment(slots[lowest])
		return Enum.ContextActionResult.Sink
	end

	ControlManager.Register("Next Weapon", false, function()
		if not selectedItem then
			return selectLowest()
		end

		local selectedSlot = selectedItem.Base.Slot

		if selectedSlot + 1 > table.maxn(slots) then
			return selectLowest()
		end

		if table.maxn(slots) == selectedSlot then
			return switchToEquipment()
		end

		for i = selectedSlot + 1, 9 do
			if slots[i] then
				return switchToEquipment(slots[i])
			end
		end
		return Enum.ContextActionResult.Pass
	end)
end

StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)