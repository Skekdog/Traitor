local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalRoundInfo = require(script.Parent.LocalRoundInfo)
local SettingCallbacks = require(script.Parent.SettingCallbacks.SettingCallbacks)
local SettingsManager = require(script.Parent.SettingsManager)
local UIManager = require(ReplicatedStorage.UIManager)

local creditPopupUI = UIManager.WaitForUI("Credits") :: UIManager.UI & {Object: typeof(UIManager.UnregisteredUIs.Credits)}
local playerlistUI = UIManager.WaitForUI("Playerlist") :: UIManager.UI & {Object: typeof(UIManager.UnregisteredUIs.Playerlist)}

LocalRoundInfo.Listen("Map", function()
	local map = LocalRoundInfo.GetMap()
	if not map then
		return
	end

	creditPopupUI.Object.Text.Text = `Map Loaded: {map:GetDisplayName()} by {map.Authors}`
	creditPopupUI:ToggleVisible(true)

	playerlistUI.Object.Info.RoundInfo.Creators.Map.Text = map.Authors
	playerlistUI.Object.Info.RoundInfo.Info.Map.Text = `Map: {map:GetDisplayName()}`

	SettingCallbacks.Fire("Use FIB Lighting", SettingsManager.GetSetting("Use FIB Lighting"))

	task.wait(5)
	creditPopupUI:ToggleVisible(false)
end, true)