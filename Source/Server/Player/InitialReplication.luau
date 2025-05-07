local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RoundHandler = require(ServerScriptService.RoundHandler)
local Replication = require(ReplicatedStorage.Shared.RoundRule.Replication)

local function replicateTo(player: Player): ()
	local round = RoundHandler.GetRound()

	if round.RoundEndMusic then
		Replication.ReplicateRoundEndMusic(player, round.RoundEndMusic.Music, round.RoundEndMusic.StartedAt)
	end

	for _, v in round:GetParticipants() do
		assert(v)
		Replication.ReplicatePlayerStatus(player, v, v:GetStatus())
		Replication.ReplicateRole(player, v, false)
		
		local corpse = v:GetCorpse()
		if corpse then
			Replication.ReplicateCorpse(player, corpse, false)
		end
	end
end

Players.PlayerAdded:Connect(replicateTo)

return nil