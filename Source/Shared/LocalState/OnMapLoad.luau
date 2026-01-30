local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GetDisplayName = require(ReplicatedStorage.Shared.RoundRule.Common.GetDisplayName)
local LocalRoundInfo = require(script.Parent.LocalRoundInfo)
local UIManager = require(ReplicatedStorage.Shared.Interface.UILib.UIManager)
local ConfirmationPrompt = require(ReplicatedStorage.Shared.Interface.Util.ConfirmationPrompt)
local SettingsUI = require(ReplicatedStorage.Shared.Settings.SettingsUI)

local alertUI = UIManager.WaitForUI("Alert") :: UIManager.UI & {Object: typeof(UIManager.UnregisteredUIs.Alert)}
local playerlistUI = UIManager.WaitForUI("Playerlist") :: UIManager.UI & {Object: typeof(UIManager.UnregisteredUIs.Playerlist)}

LocalRoundInfo.Map:Connect(function(map)
	SettingsUI.RemoveTab("Bosses")

	if not map then
		return
	end

	alertUI.Object.Text = `Map Loaded: {GetDisplayName(map)} by {map.Authors}`
	alertUI:ToggleVisible(true)

	playerlistUI.Object.Info.RoundInfo.Map.MapAuthors.Text = map.Authors
	playerlistUI.Object.Info.RoundInfo.Map.MapName.Text = `Map: {GetDisplayName(map)}`

	for name, definition in map.Bosses do
		SettingsUI.AddClickButton("Spawn " .. GetDisplayName(definition), "Bosses", "Bosses", nil, function()
			if definition.GamepassId then
				local isOwned = MarketplaceService:UserOwnsGamePassAsync(Players.LocalPlayer.UserId, definition.GamepassId)
				if not isOwned then
					MarketplaceService:PromptGamePassPurchase(Players.LocalPlayer, definition.GamepassId)
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

	task.wait(5)
	alertUI:ToggleVisible(false)
end, true)

return nil