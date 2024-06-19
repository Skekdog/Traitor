local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedFirst.RoundHandler.Types)

local remotes = ReplicatedStorage.RoundHandler

local module = {}

function module.SendUpdatedParticipants(participants: {Types.Participant}, thisParticipant: Types.Participant?, plr: Player)
	if not thisParticipant then
		for _, v in participants do
			remotes.UpdateParticipant:FireClient(plr, v:ViewPartialParticipant())
		end
		return
	end

	remotes.UpdateOwnParticipant:FireClient(plr, thisParticipant:ViewPartialSelf())
	for _, v in participants do
		if v.Player ~= thisParticipant.Player then
			remotes.UpdateParticipant:FireClient(plr, v:ViewPartialParticipant(thisParticipant))
		end
	end
end

return module