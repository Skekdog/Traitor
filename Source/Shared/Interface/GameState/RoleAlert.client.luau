local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local UIManager = require(ReplicatedStorage.Shared.Interface.UILib.UIManager)
local LocalRoundInfo = require(ReplicatedStorage.Shared.LocalState.LocalRoundInfo)
local GetDisplayName = require(ReplicatedStorage.Shared.RoundRule.Common.GetDisplayName)
local PlaySound = require(ReplicatedStorage.Shared.RoundRule.Common.PlaySound)
local Defaults = require(ReplicatedStorage.Shared.RoundRule.Defaults)

local ui = UIManager.WaitForUI("RoleAlert") 
local UI = ui.Object :: typeof(UIManager.UnregisteredUIs.RoleAlert)

local lastRole = ""
LocalRoundInfo.PlayerRoles:Connect(function(roles)
	local role = LocalRoundInfo.GetPlayerRole()

	if role.Definition.Name == lastRole or role == Defaults.Role then
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