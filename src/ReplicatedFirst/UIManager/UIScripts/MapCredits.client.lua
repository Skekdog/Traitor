local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalRoundInfo = require(ReplicatedFirst.LocalRoundInfo)
local UI = require(ReplicatedFirst.UIManager).WaitForUI("Credits")

LocalRoundInfo.Listen("MapAuthors", function(mapAuthors)
	(UI :: any).UI.Text.Text = `Map Loaded: {ReplicatedStorage.RoundHandler:GetAttribute("MapName")} by {mapAuthors}`
	UI:ToggleVisible(true)
	task.delay(5, UI.ToggleVisible, UI, false)
end)