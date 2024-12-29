local ReplicatedFirst = game:GetService("ReplicatedFirst")
local LocalRoundInfo = require(script.Parent.LocalRoundInfo)
local SettingCallbacks = require(script.Parent.SettingCallbacks.SettingCallbacks)
local SettingsManager = require(script.Parent.SettingsManager)
local UIManager = require(ReplicatedFirst.UIManager)
local UI = UIManager.WaitForUI("Credits") :: UIManager.UI & {Object: typeof(UIManager.UnregisteredUIs.Credits)}

LocalRoundInfo.Listen("Map", function()
	local map = LocalRoundInfo.GetMap()
	if not map then
		return
	end

	UI.Object.Text.Text = `Map Loaded: {map.Name} by {map.Authors}`
	UI:ToggleVisible(true)
	task.delay(5, UI.ToggleVisible, UI, false)

	SettingCallbacks.Fire("Use FIB Lighting", SettingsManager.GetSetting("Use FIB Lighting"))
end)