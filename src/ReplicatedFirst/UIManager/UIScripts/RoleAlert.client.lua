local UIManager = require(script.Parent.Parent)
local RS = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local ui = UIManager.GetUI("RoleAlert", "Popup")
RS.RoundHandler.SendRoleAlert.OnClientEvent:Connect(function(name, colour, description)
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxassetid://"..tostring("")
	sound.SoundGroup = SoundService.RoleReveals
	sound.Parent = SoundService.RoleReveals
	sound:Play()
	
	ui.UI:FindFirstChild("HintLabel").Text = description
	ui.UI:FindFirstChild("RoleLabel").Text = name
	ui.UI:FindFirstChild("RoleLabel").TextColor3 = colour
	
	ui:ToggleVisible(true)
	task.delay(5, function()
		ui:ToggleVisible(false)
	end)
end)