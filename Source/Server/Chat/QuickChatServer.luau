local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local FilterDead = require(script.Parent.FilterDead)
local GetRemote = require(ReplicatedStorage.API.GetRemote)
local QuickChat = require(ReplicatedStorage.Shared.Interface.Chat.QuickChat.QuickChat)
local Replication = require(ReplicatedStorage.Shared.RoundRule.Replication)

local remote = GetRemote("QuickChat", ReplicatedStorage.Remotes)

local rateLimits: {[Player]: number?} = {}

remote.OnServerEvent:Connect(function(player: Player, messageId: unknown, id: unknown): ()
	if typeof(messageId) ~= "number" then
		return
	end

	if typeof(id) ~= "nil" and (typeof(id) ~= "Instance" or not id:IsA("Model")) then
		return
	end

	local baseMessage = QuickChat.Messages[messageId]
	if not baseMessage then
		return
	end

	if (rateLimits[player] or 0) + 0.5 > os.clock() then
		return Replication.SendMessage(player, "Please do not flood the chat.", "Chat")
	end

	rateLimits[player] = os.clock()

	for _, v in Players:GetPlayers() do
		if FilterDead.ShouldSend(player, v) then
			ReplicatedStorage.Shared.RoundRule.Remotes.SendMessage:FireClient(v, QuickChat.FormatMessage(baseMessage, id), "QuickChat", player)
		end
	end
end)

return nil