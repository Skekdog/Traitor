local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlaceIDs = require(ReplicatedStorage.PlaceIDs)
local SafeTeleport = require(ReplicatedStorage.SafeTeleport)
local SettingsUI = require(script.Parent.SettingsUI)

SettingsUI.AddClickButton("Imperium", "Other", "Other Games", "Imperium is a Monopoly clone created by yours truly.\nIf you don't have friends to play with, you can play against bots!", function()
	SafeTeleport(PlaceIDs.Imperium, {})
end)

if game.PlaceId == PlaceIDs.TestPlace then
	SettingsUI.AddClickButton("Main Place", "Other", "Those You Trust", "Return to the main place.", function()
		SafeTeleport(PlaceIDs.MainPlace, {})
	end)
else
	SettingsUI.AddClickButton("Test Place", "Other", "Those You Trust", "Testing place for new features and updates. Things are likely to break, and may impact main game save data. Join at your own risk!", function()
		SafeTeleport(PlaceIDs.TestPlace, {})
	end)
end

return nil