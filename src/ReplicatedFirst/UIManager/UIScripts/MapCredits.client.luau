local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SettingsManager = require(ReplicatedFirst.SettingsManager)
local LocalRoundInfo = require(ReplicatedFirst.LocalRoundInfo)
local UIManager = require(ReplicatedFirst.UIManager)
local UI = UIManager.WaitForUI("Credits")

local fibSettingDefinition = SettingsManager.Settings["Use FIB Lighting"].Definition

LocalRoundInfo.Listen("MapAuthors", function(mapAuthors)
	(UI.Object :: typeof(UIManager.UnregisteredUIs.Credits)).Text.Text = `Map Loaded: {ReplicatedStorage:WaitForChild("RoundHandler"):GetAttribute("MapName")} by {mapAuthors}`
	UI:ToggleVisible(true)
	task.delay(5, UI.ToggleVisible, UI, false)

	-- If ever there is more need for yielding with LocalRoundInfo, it should be integrated in LocalRoundInfo. But as there is no need right now, nay bother
	repeat
		task.wait()
	until LocalRoundInfo.GetMap()
	assert(fibSettingDefinition.Callback)
	fibSettingDefinition.Callback(SettingsManager.GetSetting(fibSettingDefinition.Name), fibSettingDefinition.Name)
end)