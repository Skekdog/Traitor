local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GetDisplayName = require(ReplicatedStorage.Shared.RoundRule.Common.GetDisplayName)
local LocalRoundInfo = require(script.Parent.LocalRoundInfo)
local UIManager = require(ReplicatedStorage.Shared.Interface.UILib.UIManager)

local alertUI = UIManager.WaitForUI("Alert") :: UIManager.UI & {Object: typeof(UIManager.UnregisteredUIs.Alert)}
local playerlistUI = UIManager.WaitForUI("Playerlist") :: UIManager.UI & {Object: typeof(UIManager.UnregisteredUIs.Playerlist)}

LocalRoundInfo.Map:Connect(function(map)
	if not map then
		return
	end

	alertUI.Object.Text = `Map Loaded: {GetDisplayName(map.Definition)} by {map.Definition.Authors}`
	alertUI:ToggleVisible(true)

	playerlistUI.Object.Info.RoundInfo.Creators.Map.Text = map.Definition.Authors
	playerlistUI.Object.Info.RoundInfo.Info.Map.Text = `Map: {GetDisplayName(map.Definition)}`

	task.wait(5)
	alertUI:ToggleVisible(false)
end, true)