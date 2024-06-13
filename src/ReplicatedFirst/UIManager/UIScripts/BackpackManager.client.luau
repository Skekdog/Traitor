local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local InventoryManager = require(script.Parent.Parent.Parent.InventoryManager)
local Types = require(script.Parent.Parent.Parent.RoundHandler.Types)
local UIManager = require(ReplicatedFirst.UIManager)

local plr = Players.LocalPlayer
local backpack = UIManager.WaitForUI("Backpack").Object :: typeof(ReplicatedFirst.UIManager.UnregisteredUIs.Backpack)

local function switchToEquipment(equipment: Types.Equipment)
	print("Switching to equipment: " .. equipment.Name)
end

(ReplicatedStorage :: any):WaitForChild("ServerClient").InventoryEvent.OnClientEvent:Connect(function(event: InventoryManager.InventoryEvent, equipment: Types.Equipment)
	if event == "Add" then
		InventoryManager.AddEquipment(plr, equipment)
		local clone = backpack.Sample:Clone()
		clone.Text = equipment.Name
		clone.TextLabel.Text = `[{equipment.Extras.Slot}]`
		clone.Visible = true
		clone.Name = equipment.Name

		clone.MouseButton1Click:Connect(function()
			switchToEquipment(equipment)
		end)

		clone.Parent = backpack
	elseif event == "Remove" then
		InventoryManager.RemoveEquipment(plr, equipment)
		local found = backpack:FindFirstChild(equipment.Name)
		if found then
			found:Destroy()
		end
	end
end)

StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)