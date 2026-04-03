local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local GetDeterminer = require(ReplicatedStorage.Shared.Grammar.GetDeterminer)
local UIManager = require(ReplicatedStorage.Shared.Interface.UILib.UIManager)
local LocalParticipantInfo = require(ReplicatedStorage.Shared.LocalState.LocalParticipantInfo)
local GetDisplayName = require(ReplicatedStorage.Shared.RoundRule.Common.GetDisplayName)
local PlaySound = require(ReplicatedStorage.API.PlaySound)
local Defaults = require(ReplicatedStorage.Shared.RoundRule.Defaults)

local ui = UIManager.WaitForUI("RoleAlert")
local UI = ui.Object :: typeof(UIManager.UnregisteredUIs.RoleAlert)

local participant = LocalParticipantInfo.GetParticipant()
local lastRole = ""
participant.Role:Connect(function(role)
	if role.Definition.Name == lastRole or role == Defaults.Role then
		lastRole = role.Definition.Name
		return
	end

	lastRole = role.Definition.Name
	PlaySound(role.Definition.Sound, nil, nil, {SoundGroup = SoundService.RoleReveals :: SoundGroup})

	UI.Frame.UIGradient.Color = ColorSequence.new(role.Definition.Color, Color3.new(1, 1, 1))
	UI:FindFirstChild("HintLabel").Text = role.Definition.Description
	UI:FindFirstChild("RoleLabel").Text = GetDisplayName(role.Definition)
	UI:FindFirstChild("RoleLabel").TextColor3 = role.Definition.Color
	UI.TextLabel.Text = "You are " .. GetDeterminer(GetDisplayName(role.Definition)) .. "..."

	ui:ToggleVisible(true)
	task.delay(5, ui.ToggleVisible, ui, false)
end, true)

return nil