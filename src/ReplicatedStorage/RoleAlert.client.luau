local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local LocalRoundInfo = require(script.Parent.LocalRoundInfo)
local UIManager = require(script.Parent.UIManager)

local ui = UIManager.WaitForUI("RoleAlert") 
local UI = ui.Object :: typeof(UIManager.UnregisteredUIs.RoleAlert)

LocalRoundInfo.Listen("PlayerRole", function()
	local role = LocalRoundInfo.GetPlayerRole(Players.LocalPlayer)
	if role then
		local sound = Instance.new("Sound")
		sound.SoundId = role.Definition.Sound
		sound.SoundGroup = SoundService.RoleReveals
		sound.Parent = SoundService.RoleReveals

		sound.Ended:Connect(function()
			sound:Destroy()
		end)
		sound:Play()
		
		UI:FindFirstChild("HintLabel").Text = role.Definition.Description
		UI:FindFirstChild("RoleLabel").Text = role.Definition.DisplayName or role.Definition.Name
		UI:FindFirstChild("RoleLabel").TextColor3 = role.Definition.Color
		
		ui:ToggleVisible(true)
		task.delay(5, ui.ToggleVisible, ui, false)
	end
end, true)