local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Message = require(ReplicatedStorage.API.Interface.Message)
local GetDisplayName = require(ReplicatedStorage.Shared.RoundRule.Common.GetDisplayName)
local LocalRoundInfo = require(script.Parent.LocalRoundInfo)
local UIManager = require(ReplicatedStorage.Shared.Interface.UILib.UIManager)
local ConfirmationPrompt = require(ReplicatedStorage.Shared.Interface.Util.ConfirmationPrompt)
local Gamepass = require(ReplicatedStorage.Shared.Monetisation.Gamepass)
local SettingsUI = require(ReplicatedStorage.Shared.Settings.SettingsUI)

local playerlistUI = UIManager.WaitForUI("Playerlist") :: UIManager.UI & {Object: typeof(UIManager.UnregisteredUIs.Playerlist)}

LocalRoundInfo.Map:Connect(function(map)
	SettingsUI.RemoveTab("Bosses")

	if not map then
		return
	end

	Message.Popup(`Map Loaded: {GetDisplayName(map)} by {map.Authors}`)

	playerlistUI.Object.Info.RoundInfo.Map.MapAuthors.Text = map.Authors
	playerlistUI.Object.Info.RoundInfo.Map.MapName.Text = `Map: {GetDisplayName(map)}`

	for name, definition in map.Bosses do
		SettingsUI.AddClickButton("Spawn " .. GetDisplayName(definition), "Bosses", "Bosses", nil, function()
			if definition.GamepassId then
				if not Gamepass.IsOwned(definition.GamepassId, Players.LocalPlayer) then
					return
				end
			end
			if map.Structure.Static:GetAttribute("BossSpawned") then
				ConfirmationPrompt("Please wait before spawning another boss.", function() end, "Okay", "")
				return
			end
			ReplicatedStorage.Remotes.ClientServer.SpawnBoss:FireServer(name)
		end)
	end
end, true)

return nil