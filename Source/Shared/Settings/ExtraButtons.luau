local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Settings = require(script.Parent.Settings)
local UIManager = require(ReplicatedStorage.Shared.Interface.UILib.UIManager)
local SafeTeleport = require(ReplicatedStorage.Shared.Util.SafeTeleport)
local ConfirmationPrompt = require(ReplicatedStorage.Shared.Interface.Util.ConfirmationPrompt)
local PlaceIDs = require(ReplicatedStorage.Shared.Util.PlaceIDs)
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

SettingsUI.AddClickButton("View Welcome", "Other", "Those You Trust", nil, function()
	UIManager.WaitForUI("Welcome"):ToggleVisible(true)
end)

-- for _, v in ReplicatedStorage.Assets.Licenses:GetChildren() do
-- 	assert(v:IsA("StringValue"))
-- 	SettingsUI.AddClickButton(v.Name, "Other", "Acknowledgements", "These are third-party packages, without which the game would not be possible!", function()
-- 		local ui = UIManager.WaitForUI("Acknowledgements") :: UIManager.UI & {Object: typeof(UIManager.UnregisteredUIs.Acknowledgements)}
-- 		ui.Object.ScrollingFrame.License.Text = v.Value
-- 		ui:ToggleVisible(true)
-- 	end)
-- end

SettingsUI.AddClickButton("Reset to Defaults", "Other", "Settings", "Resets all settings to their default values. Cannot be undone.", function()
	ConfirmationPrompt("Are you sure you want to reset all settings to their defaults?", function(response: boolean): ()
		if not response then
			return
		end

		for i, v in Settings.ResetAll() do
			SettingsUI.UpdateButtonValue(i, v)
		end
	end)
end)

return nil