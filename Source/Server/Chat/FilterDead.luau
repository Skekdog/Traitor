local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HookOnMessage = require(script.Parent.HookOnMessage)
local GetParticipant = require(ReplicatedStorage.API.GetParticipant)
local GetRound = require(ReplicatedStorage.API.GetRound)

local FilterDead = {}

FilterDead.Disabled = false

HookOnMessage(function(message, source)
	if FilterDead.Disabled then
		return true
	end

	local round = GetRound()
	if not round:IsInProgress() then
		return true
	end

	-- note: TextSource.Name is set to DisplayName, so we can't use that
	local sender = Players:GetPlayerByUserId(message.TextSource.UserId)
	local receiver = Players:GetPlayerByUserId(source.UserId)

	local senderParticipant = if sender then GetParticipant(sender.Name) else nil
	local receiverParticipant = if receiver then GetParticipant(receiver.Name) else nil

	if not senderParticipant or not senderParticipant:IsAlive() then
		return not receiverParticipant or not receiverParticipant:IsAlive()
	end

	return true
end)

return FilterDead