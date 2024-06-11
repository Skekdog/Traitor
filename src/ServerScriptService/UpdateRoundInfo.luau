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

function module.SendUpdatedParticipants(participants: {Types.Participant}, thisParticipant: Types.Participant?, plr: Player)
	if not thisParticipant then
		for _, v in participants do
			remotes.UpdateParticipant:FireClient(plr, minimalParticipant(v))
		end
		return
	end

	for _, v in participants do
		if v.Player ~= thisParticipant.Player then
			remotes.UpdateParticipant:FireClient(plr, thisParticipant:ViewPartialParticipant(v))
			continue
		end
		local p = table.clone(thisParticipant)
		p.Round = nil :: any

		-- Edge cases, cause a cyclic table - not good!
		if p.KilledByParticipant and p.KilledByParticipant.Player == p.Player then
			p.KilledByParticipant = nil
		end
		for i, v in p.KillList do
			if v.Player == p.Player then
				p.KillList[i] = nil
			end
		end
		for i, v in p.SearchedBy do
			if v.Player == p.Player then
				p.SearchedBy[i] = nil
			end
		end
		for i, v in p.SelfDefenseList do
			if v.Against.Player == p.Player then
				p.SelfDefenseList[i] = nil
			end
		end

		print(p)
		remotes.UpdateOwnParticipant:FireClient(plr, p)
	end
end

return module