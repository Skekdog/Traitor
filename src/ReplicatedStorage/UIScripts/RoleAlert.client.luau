local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local LocalRoundInfo = require(ReplicatedStorage.LocalRoundInfo)
local GetDisplayName = require(ReplicatedStorage.RoundRule.Common.GetDisplayName)
local PlaySound = require(ReplicatedStorage.RoundRule.Common.PlaySound)
local UIManager = require(ReplicatedStorage.UIManager)

local ui = UIManager.WaitForUI("RoleAlert") 
local UI = ui.Object :: typeof(UIManager.UnregisteredUIs.RoleAlert)

local lastRole: string?
LocalRoundInfo.Listen("PlayerRole", function()
	local role = LocalRoundInfo.GetPlayerRole(Players.LocalPlayer.Name)
	if not role then
		lastRole = nil
		return
	end

	if role.Definition.Name == lastRole then
		return
	end
	
	lastRole = role.Definition.Name
	PlaySound(role.Definition.Sound, nil, nil, {SoundGroup = SoundService.RoleReveals :: SoundGroup})
	
	UI:FindFirstChild("HintLabel").Text = role.Definition.Description
	UI:FindFirstChild("RoleLabel").Text = GetDisplayName(role.Definition)
	UI:FindFirstChild("RoleLabel").TextColor3 = role.Definition.Color
	
	ui:ToggleVisible(true)
	task.delay(5, ui.ToggleVisible, ui, false)
end, true)