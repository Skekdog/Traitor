local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GetDisplayName = require(ReplicatedStorage.Shared.RoundRule.Common.GetDisplayName)
local FIBLighting = require(ReplicatedStorage.Shared.Settings.Callbacks.FIBLighting)
local Settings = require(ReplicatedStorage.Shared.Settings.Settings)
local LocalRoundInfo = require(script.Parent.LocalRoundInfo)
local UIManager = require(ReplicatedStorage.Shared.Interface.UILib.UIManager)

local creditPopupUI = UIManager.WaitForUI("Credits") :: UIManager.UI & {Object: typeof(UIManager.UnregisteredUIs.Credits)}
local playerlistUI = UIManager.WaitForUI("Playerlist") :: UIManager.UI & {Object: typeof(UIManager.UnregisteredUIs.Playerlist)}

LocalRoundInfo.Map:Connect(function(map)
	if not map then
		return
	end

	creditPopupUI.Object.Text.Text = `Map Loaded: {GetDisplayName(map)} by {map.Authors}`
	creditPopupUI:ToggleVisible(true)

	playerlistUI.Object.Info.RoundInfo.Creators.Map.Text = map.Authors
	playerlistUI.Object.Info.RoundInfo.Info.Map.Text = `Map: {GetDisplayName(map)}`

	FIBLighting("Use FIB Lighting", Settings.GetSetting("Use FIB Lighting") :: Settings.BooleanValue)

	task.wait(5)
	creditPopupUI:ToggleVisible(false)
end, true)