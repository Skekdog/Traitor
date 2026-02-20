local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GetRemote = require(ReplicatedStorage.API.GetRemote)
local Notification = require(ReplicatedStorage.API.Notification)
local QuickChat = require(ReplicatedStorage.Shared.Interface.Chat.QuickChat.QuickChat)

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
		return Notification("Please do not flood the chat.", "Chat", player)
	end

	rateLimits[player] = os.clock()

	Notification(QuickChat.FormatMessage(baseMessage, id), "QuickChat", nil, player)
end)

return nil