local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")
local Notification = require(ReplicatedStorage.API.Notification)
local HookOnMessage = require(script.Parent.HookOnMessage)

HookOnMessage.FinalHook = function(message, source)
	if not message.TextSource then
		return true
	end

	local sender = Players:GetPlayerByUserId(message.TextSource.UserId)
	local recipient = Players:GetPlayerByUserId(source.UserId)

	if not sender or not recipient then
		return true
	end

	if not TextChatService:CanUsersChatAsync(message.TextSource.UserId, source.UserId) then
		Notification("|*|*|*|*|", "Relay", recipient, sender)
	end

	return true
end

return nil