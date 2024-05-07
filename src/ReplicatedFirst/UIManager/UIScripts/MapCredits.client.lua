local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UI = require(ReplicatedFirst.UIManager).WaitForUI("Credits")

ReplicatedStorage.RoundHandler.MapChanged.OnClientEvent:Connect(function(mapCreator, map, gamemode)
	(UI :: any).UI.Text.Text = `Map Loaded: {map} by {mapCreator}`
	UI:ToggleVisible(true)
	task.delay(5, UI.ToggleVisible, UI, false)
end)