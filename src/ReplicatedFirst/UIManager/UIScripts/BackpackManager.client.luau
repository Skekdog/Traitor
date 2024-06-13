local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local ControlManager = require(script.Parent.Parent.Parent.ControlManager)
local InventoryManager = require(script.Parent.Parent.Parent.InventoryManager)
local Types = require(script.Parent.Parent.Parent.RoundHandler.Types)
local UIManager = require(ReplicatedFirst.UIManager)

local plr = Players.LocalPlayer
local backpack = UIManager.WaitForUI("Backpack").Object :: typeof(ReplicatedFirst.UIManager.UnregisteredUIs.Backpack)

local selectedEquipment: Types.Equipment?

local function unequip(equipment: Types.Equipment): ()
	print("Unequipping", equipment.Name)
	local found = backpack:FindFirstChild(equipment.Name) :: TextButton
	if found then
		found.BackgroundTransparency = 0.75
	end
	InventoryManager.Unequip(plr, equipment)
	selectedEquipment = nil
end

-- Surely there is a better way to do this
local function switchToEquipment(equipment: Types.Equipment?)
	if equipment then
		if equipment == selectedEquipment then
			return unequip(equipment)
		else
			InventoryManager.Equip(plr, equipment)
			local found = backpack:FindFirstChild(equipment.Name) :: TextButton
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
end

local slots: {[number]: Types.Equipment} = {}
(ReplicatedStorage :: any):WaitForChild("ServerClient").InventoryEvent.OnClientEvent:Connect(function(event: InventoryManager.InventoryEvent, equipment: Types.Equipment)
	if event == "Add" then
		InventoryManager.AddEquipment(plr, equipment)
		local clone = backpack.Sample:Clone()
		clone.Text = equipment.Name
		clone.TextLabel.Text = `[{equipment.Extras.Slot}]`
		clone.Visible = true

		clone.LayoutOrder = equipment.Extras.Slot
		clone.Name = equipment.Name

		slots[equipment.Extras.Slot] = equipment
		clone.MouseButton1Click:Connect(function()
			switchToEquipment(equipment)
		end)

		clone.Parent = backpack
	elseif event == "Remove" then
		InventoryManager.RemoveEquipment(plr, equipment)
		local found = backpack:FindFirstChild(equipment.Name)
		if found then
			slots[equipment.Extras.Slot] = nil
			found:Destroy()
		end
	end
end)

local MAX_SLOT = 9

for i = 1, MAX_SLOT do
	ControlManager.Register("Slot "..i, false, function()
		local equipment = slots[i]
		if equipment then
			switchToEquipment(equipment)
		end
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
			return
		end
		return switchToEquipment(slots[lowest])
	end

	ControlManager.Register("Next Weapon", false, function()
		if not selectedEquipment then
			return selectLowest()
		end

		local selectedSlot = selectedEquipment.Extras.Slot

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
	end)
end

StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)