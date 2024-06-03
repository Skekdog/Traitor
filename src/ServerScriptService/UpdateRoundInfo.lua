local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedFirst.RoundHandler.Types)

local remotes = ReplicatedStorage.RoundHandler

local module = {}

local function minimalParticipant(participant: Types.Participant)
	return {
		Player = participant.Player,
		Status = participant.Status,
	}
end

local function makeNonCyclicParticipant(participant: Types.Participant): Types.Participant -- actually Round is nil
	local nonCyclic = {}
	for k, v in participant do
		if k == "Round" then
			continue
		end
		nonCyclic[k] = v
	end
	return nonCyclic :: any
end

function module.SendUpdatedParticipants(participants: {Types.Participant}, thisParticipant: Types.Participant?, plr: Player)
	if not thisParticipant then
		for _, v in participants do
			remotes.UpdateParticipant:FireClient(plr, minimalParticipant(v))
		end
		return
	end
	for _, v in participants do
		if v.Player == thisParticipant.Player then
			remotes.UpdateOwnParticipant:FireClient(plr, makeNonCyclicParticipant(thisParticipant))
			continue
		end
        print("send other")
		remotes.UpdateParticipant:FireClient(plr, thisParticipant:ViewPartialParticipant(v))
	end
end

return module