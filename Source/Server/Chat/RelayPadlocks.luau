local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")
local HookOnMessage = require(script.Parent.HookOnMessage)

HookOnMessage.SetFinalHook(function(message, source)
	if not message.TextSource then
		return true
	end

	local sender = Players:GetPlayerByUserId(message.TextSource.UserId)
	local recipient = Players:GetPlayerByUserId(source.UserId)

	if not sender or not recipient then
		return true
	end

	if not TextChatService:CanUsersChatAsync(message.TextSource.UserId, source.UserId) then
		ReplicatedStorage.Shared.RoundRule.Remotes.SendMessage:FireClient(recipient, "●●●●●●", "Relay", sender)
	end

	return true
end)

return nil