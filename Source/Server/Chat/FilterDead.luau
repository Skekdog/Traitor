local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HookOnMessage = require(script.Parent.HookOnMessage)
local GetParticipant = require(ReplicatedStorage.API.GetParticipant)
local GetRound = require(ReplicatedStorage.API.GetRound)

local FilterDead = {}

FilterDead.Disabled = false

function FilterDead.ShouldSend(sender: Player?, receiver: Player?): boolean
	if FilterDead.Disabled then
		return true
	end

	local round = GetRound()
	if not round:IsInProgress() then
		return true
	end

	local senderParticipant = if sender then GetParticipant(sender.Name) else nil
	local receiverParticipant = if receiver then GetParticipant(receiver.Name) else nil

	if not senderParticipant or not senderParticipant:IsAlive() then
		return not receiverParticipant or not receiverParticipant:IsAlive()
	end

	return true
end

HookOnMessage.Hook(function(message, source)
	local sender = Players:GetPlayerByUserId(message.TextSource.UserId)
	local receiver = Players:GetPlayerByUserId(source.UserId)

	return FilterDead.ShouldSend(sender, receiver)
end)

return FilterDead