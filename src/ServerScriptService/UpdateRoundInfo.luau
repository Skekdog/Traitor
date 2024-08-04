local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedFirst.RoundHandler.Types)

local remotes = ReplicatedStorage.RoundHandler

local module = {}

function module.UpdateOwnParticipant(participant: Types.ClientOwnParticipant): ()
	remotes.UpdateOwnParticipant:FireClient(participant.Player, participant.Player, participant)
end

function module.UpdateParticipant(target: Types.Participant): ()
	for _, v in Players:GetPlayers() do
		local participant = target.Round:GetParticipant(v.Name)
		if v == target.Player then
			remotes.UpdateOwnParticipant:FireClient(v, v, target:ViewPartialSelf())
		else
			remotes.UpdateParticipant:FireClient(v, target.Player, target:ViewPartialParticipant(participant))
		end
	end
end

function module.UpdatePlayersForPlayer(player: Player, round: Types.Round?): ()
	local ownParticipant = if round then round:GetParticipant(player.Name) else nil
	for _, v in Players:GetPlayers() do
		if v == player then
			remotes.UpdateOwnParticipant:FireClient(player, player, if ownParticipant then ownParticipant:ViewPartialSelf() else nil)
		else
			local participant = if round then round:GetParticipant(v.Name) else nil
			if participant then
				remotes.UpdateParticipant:FireClient(player, v, participant:ViewPartialParticipant(ownParticipant))
			else
				remotes.UpdateParticipant:FireClient(player, v, nil)
			end
		end
	end
end

function module.UpdatePlayers(round: Types.Round?): ()
	for _, v in Players:GetPlayers() do
		module.UpdatePlayersForPlayer(v, round)
	end
end

function module.AddPlayer(player: Player): ()
	for _, v in Players:GetPlayers() do
		if v ~= player then
			remotes.UpdateParticipant:FireClient(v, player, nil)
		end
	end
end

return module