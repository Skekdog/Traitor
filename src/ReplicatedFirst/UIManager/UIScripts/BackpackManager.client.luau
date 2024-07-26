local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local UIAnimation = require(script.Parent.Parent.Parent.UIAnimation)
local ControlManager = require(ReplicatedFirst.ControlManager)
local InventoryManager = require(ReplicatedFirst.InventoryManager)
local ItemTypes = require(ReplicatedFirst.ItemTypes)
local UIManager = require(ReplicatedFirst.UIManager)

local plr = Players.LocalPlayer
local backpack = UIManager.WaitForUI("Backpack").Object :: typeof(UIManager.UnregisteredUIs.Backpack)

local sample = backpack.Sample
sample.Parent = nil -- so that it doesn't get counted for animation

local selectedEquipment: ItemTypes.Item?

local function unequip(equipment: ItemTypes.Item): ()
	local found = backpack:FindFirstChild(equipment.Base.Name) :: TextButton
	if found then
		found.BackgroundTransparency = 0.75
	end
	InventoryManager.Unequip(plr, equipment)
	selectedEquipment = nil
end

-- Surely there is a better way to do this
local function switchToEquipment(equipment: ItemTypes.Item?)
	if equipment then
		if (equipment :: any) == selectedEquipment then
			unequip(equipment)
			return Enum.ContextActionResult.Sink
		else
			InventoryManager.Equip(plr, equipment)
			local found = backpack:FindFirstChild(equipment.Base.Name) :: TextButton
			if found then
				found.BackgroundTransparency = 0.25
			end

			if selectedEquipment then
				unequip(selectedEquipment)
			end
		end
	elseif selectedEquipment then
		unequip(selectedEquipment)
	end
	selectedEquipment = equipment
	return Enum.ContextActionResult.Sink
end

-- 25 padding, X size is 0.065
local function move(clone: typeof(sample), order: number, middle: number): ()
	local difference = order - middle
	local relativePosition
	print(difference)
	if order == middle then
		relativePosition = UDim2.new()
	else
		relativePosition = UDim2.new(0.098 * difference, if difference < 0 then -25 else 25, 0, 0)
	end

	if math.abs(difference) == 1 then
		relativePosition -= UDim2.fromScale(0.033 * if difference < 0 then -1 else 1, 0)
	end

	UIAnimation.Animate(clone, TweenInfo.new(0.2), {Position = UDim2.fromScale(0.5, 0) + relativePosition})
end

local slots: {[number]: ItemTypes.Item?} = {}
local function add(equipment: ItemTypes.Item): ()
	InventoryManager.AddEquipment(plr, equipment)

	local clone = sample:Clone()
	clone.Text = equipment.Base.Name
	clone.TextLabel.Text = `[{equipment.Base.Slot}]`
	clone.LayoutOrder = equipment.Base.Slot

	clone.Position = UDim2.fromScale(0.5, 1.2)
	clone.Visible = true

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

local function remove(equipment: ItemTypes.Item)
	InventoryManager.RemoveEquipment(plr, equipment)

	local found = backpack.Container:FindFirstChild(equipment.Base.Name)
	local buttons = backpack.Container:GetChildren() :: {any}

	if found then
		found.Parent = nil
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

	if selectedEquipment and equipment.Base.Name == selectedEquipment.Base.Name then
		selectedEquipment = nil
	end

	table.sort(buttons, function(a, b)
		return a.LayoutOrder < b.LayoutOrder
	end)

	for _, v in buttons do
		move(v, table.find(buttons, v) :: number, (#buttons + 1) / 2)
	end
end

ReplicatedStorage:WaitForChild("ServerClient").InventoryEvent.OnClientEvent:Connect(function(event: InventoryManager.InventoryEvent, equipment: ItemTypes.Item?)
	if not equipment then
		return
	end
	if event == "Add" then
		add(equipment)
	elseif event == "Remove" then
		remove(equipment)
	elseif event == "Unequip" then
		if selectedEquipment and equipment.Base.Name == selectedEquipment.Base.Name then
			selectedEquipment = nil
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

local function minN(table: {[number]: any?}): number?
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
		if not selectedEquipment then
			return selectLowest()
		end

		local selectedSlot = selectedEquipment.Base.Slot

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