local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ConfirmationPrompt = require(ReplicatedStorage.ConfirmationPrompt)
local PlaceIDs = require(ReplicatedStorage.PlaceIDs)
local SafeTeleport = require(ReplicatedStorage.SafeTeleport)
local UIManager = require(ReplicatedStorage.UIManager)
local SettingsUI = require(script.Parent.SettingsUI)

local function promptTeleport(name: string, placeId: number): ()
	ConfirmationPrompt(`Are you sure you want to go to {name}?`, function(response: boolean)
		if not response then
			return
		end

		SafeTeleport(placeId, {})
	end)
end

SettingsUI.AddClickButton("Imperium", "Other", "Other Games", "Imperium is a Monopoly clone created by yours truly.\nIf you don't have friends to play with, you can play against bots!", function()
	promptTeleport("Imperium", PlaceIDs.Imperium)
end)

if game.PlaceId == PlaceIDs.TestPlace then
	SettingsUI.AddClickButton("Main Place", "Other", "Those You Trust", "Return to the main place.", function()
		promptTeleport("Main Place", PlaceIDs.MainPlace)
	end)
else
	SettingsUI.AddClickButton("Test Place", "Other", "Those You Trust", "Testing place for new features and updates. Things are likely to break, and may impact main game save data. Join at your own risk!", function()
		promptTeleport("Test Place", PlaceIDs.TestPlace)
	end)
end

SettingsUI.AddClickButton("View Notice", "Other", "Those You Trust", nil, function()
	UIManager.WaitForUI("Notice"):ToggleVisible(true)
end)

return nil