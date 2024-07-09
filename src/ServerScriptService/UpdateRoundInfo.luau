local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedFirst.RoundHandler.Types)

local remotes = ReplicatedStorage.RoundHandler

local module = {}

function module.UpdateParticipant(participant: Types.Participant, nillify: boolean?)
	for _, v in Players:GetPlayers() do
		if v == participant.Player then
			remotes.UpdateOwnParticipant:FireClient(v, if nillify then nil else participant:ViewPartialSelf())
		else
			remotes.UpdateParticipant:FireClient(v, if nillify then participant.Player.Name else participant:ViewPartialParticipant(participant.Round:GetParticipant(v.Name)))
		end
	end
end

function module.UpdateOwnParticipant(participant: Types.Participant | Types.ClientOwnParticipant)
	remotes.UpdateOwnParticipant:FireClient(participant.Player, if participant.Kind == "Participant" then participant:ViewPartialSelf() else participant)
end

function module.UpdateParticipantForPlayer(participant: Types.Participant, player: Player)
	if player == participant.Player then
		module.UpdateOwnParticipant(participant)
	else
		remotes.UpdateParticipant:FireClient(player, participant:ViewPartialParticipant(participant.Round:GetParticipant(player.Name)))
	end
end

return module