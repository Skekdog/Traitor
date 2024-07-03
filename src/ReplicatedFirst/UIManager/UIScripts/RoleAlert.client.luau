local UIManager = require(script.Parent.Parent)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local ui = UIManager.WaitForUI("RoleAlert") 
local UI = ui.Object :: typeof(UIManager.UnregisteredUIs.RoleAlert)
(ReplicatedStorage:WaitForChild("RoundHandler") :: typeof(ReplicatedStorage.RoundHandler)).SendRoleAlert.OnClientEvent:Connect(function(name, colour, description, soundId)
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxassetid://"..tostring(soundId)
	sound.SoundGroup = SoundService.RoleReveals
	sound.Parent = SoundService.RoleReveals

	sound.Ended:Connect(function()
		sound:Destroy()
	end)
	sound:Play()
	
	UI:FindFirstChild("HintLabel").Text = description
	UI:FindFirstChild("RoleLabel").Text = name
	UI:FindFirstChild("RoleLabel").TextColor3 = colour
	
	ui:ToggleVisible(true)
	task.delay(5, ui.ToggleVisible, ui, false)
end)