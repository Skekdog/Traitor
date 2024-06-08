local UIManager = require(script.Parent.Parent)
local RS = game:GetService("ReplicatedStorage")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local SoundService = game:GetService("SoundService")

local ui = UIManager.WaitForUI("RoleAlert") 
local UI = ui.UI :: typeof(ReplicatedFirst.UIManager.UnregisteredUIs.Popup.RoleAlert)
RS.RoundHandler.SendRoleAlert.OnClientEvent:Connect(function(name, colour, description, soundId)
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxassetid://"..tostring(soundId)
	sound.SoundGroup = SoundService.RoleReveals
	sound.Parent = SoundService.RoleReveals
	sound:Play()
	
	UI:FindFirstChild("HintLabel").Text = description
	UI:FindFirstChild("RoleLabel").Text = name
	UI:FindFirstChild("RoleLabel").TextColor3 = colour
	
	ui:ToggleVisible(true)
	task.delay(5, ui.ToggleVisible, ui, false)
end)