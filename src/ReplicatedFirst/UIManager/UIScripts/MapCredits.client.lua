local UI = require(game:GetService("ReplicatedFirst").UIManager).WaitForUI("MapCredits").UI
local ReplicatedStorage = game:GetService("ReplicatedStorage")
ReplicatedStorage.ServerClient.MapChanged.OnClientEvent:Connect(function(mapCreator, map, gamemode)
	UI.Text.Text = string.format("Map Loaded: %s by %s", map, mapCreator)
	UI.Visible = true
	task.delay(5, function()UI.Visible = false end)
end)