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
		remotes.UpdateOwnParticipant:FireClient(plr, {
			Status = v.Status,
			Role = v.Role,
			Credits = v.Credits,
		})
	end
end

return module