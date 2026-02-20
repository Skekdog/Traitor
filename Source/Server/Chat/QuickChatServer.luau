local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GetRemote = require(ReplicatedStorage.API.GetRemote)
local Notification = require(ReplicatedStorage.API.Notification)
local QuickChat = require(ReplicatedStorage.Shared.Interface.Chat.QuickChat.QuickChat)

local remote = GetRemote("QuickChat", ReplicatedStorage.Remotes)

remote.OnServerEvent:Connect(function(player: Player, messageId: unknown, id: unknown): ()
	if typeof(messageId) ~= "number" then
		return print("no")
	end

	if typeof(id) ~= "nil" and (typeof(id) ~= "Instance" or not id:IsA("Model")) then
		return print("nah")
	end

	local baseMessage = QuickChat.Messages[messageId]
	if not baseMessage then
		return print("gosh")
	end

	Notification(QuickChat.FormatMessage(baseMessage, id), "QuickChat", nil, player)
end)

return nil