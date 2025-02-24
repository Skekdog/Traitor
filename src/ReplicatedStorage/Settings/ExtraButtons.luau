local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlaceIDs = require(ReplicatedStorage.PlaceIDs)
local SafeTeleport = require(ReplicatedStorage.SafeTeleport)
local SettingsUI = require(script.Parent.SettingsUI)

SettingsUI.AddClickButton("Imperium", "Other", "Other Games", "Imperium is a Monopoly clone created by yours truly.\nIf you don't have friends to play with, you can play against bots!", function()
	SafeTeleport(PlaceIDs.Imperium, {})
end)

return nil