local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local ControlManager = require(ReplicatedFirst.ControlManager)
local InventoryManager = require(ReplicatedFirst.InventoryManager)
local ItemTypes = require(ReplicatedFirst.ItemsManager.ItemTypes)
local UIManager = require(ReplicatedFirst.UIManager)

local plr = Players.LocalPlayer
local backpack = UIManager.WaitForUI("Backpack").Object :: typeof(UIManager.UnregisteredUIs.Backpack)

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

local slots: {[number]: ItemTypes.Item} = {}
(ReplicatedStorage :: any):WaitForChild("ServerClient").InventoryEvent.OnClientEvent:Connect(function(event: InventoryManager.InventoryEvent, equipment: ItemTypes.Item)
	if event == "Add" then
		InventoryManager.AddEquipment(plr, equipment)
		local clone = backpack.Sample:Clone()
		clone.Text = equipment.Base.Name
		clone.TextLabel.Text = `[{equipment.Base.Slot}]`
		clone.Visible = true

		clone.LayoutOrder = equipment.Base.Slot
		clone.Name = equipment.Base.Name

		slots[equipment.Base.Slot] = equipment
		clone.MouseButton1Click:Connect(function()
			switchToEquipment(equipment)
		end)

		clone.Parent = backpack
	elseif event == "Remove" then
		InventoryManager.RemoveEquipment(plr, equipment)
		local found = backpack:FindFirstChild(equipment.Base.Name)
		if found then
			slots[equipment.Base.Slot] = nil
			found:Destroy()
		end

		if selectedEquipment and equipment.Base.Name == selectedEquipment.Base.Name then
			selectedEquipment = nil
		end
	elseif event == "Unequip" then
		if selectedEquipment and equipment.Base.Name == selectedEquipment.Base.Name then
			selectedEquipment = nil
		end
	end
end)

local MAX_SLOT = 9

for i = 1, MAX_SLOT do
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

		for i = selectedSlot + 1, MAX_SLOT do
			if slots[i] then
				return switchToEquipment(slots[i])
			end
		end
		return Enum.ContextActionResult.Pass
	end)
end

StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)