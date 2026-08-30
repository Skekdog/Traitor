local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RoundHandler = require(script.Parent.RoundHandler)
local Message = require(ReplicatedStorage.API.Interface.Message)
local IsLabs = require(ReplicatedStorage.Shared.Places.IsLabs)
local SafeTeleport = require(ReplicatedStorage.Shared.Util.SafeTeleport)

local isScheduled = false

local DEFAULT_MESSAGE = "This server is being shutdown and will restart soon."

local messages: {[Enum.CloseReason]: string?} = {
	[Enum.CloseReason.DeveloperUpdate] = "A new version is available. This server will restart soon.",
	[Enum.CloseReason.RobloxMaintenance] = "Roblox is shutting this server down for maintenance and will restart soon.",
}

game.ServerRestartScheduled:Connect(function(scheduledTime, reason, attributes): ()
	Message.Chat(messages[reason] or DEFAULT_MESSAGE, "All")
	isScheduled = true
end)

RoundHandler.Round:Connect(function()
	if not isScheduled then
		return
	end

	Message.Chat("The server is restarting.", "All")

	if IsLabs then
		for _, player in Players:GetPlayers() do
			player:Kick("This server has shut down.")
		end

		return
	end

	SafeTeleport(game.PlaceId, Players:GetPlayers())
end)

return nil