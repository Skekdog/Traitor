local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CreateRadarPoint = require(ReplicatedStorage.API.CreateRadarPoint)
local Crouch = require(script.Parent.Crouch)
local CorpseInfo = require(ReplicatedStorage.Shared.Interface.GameState.CorpseInfo)
local LocalParticipantInfo = require(ReplicatedStorage.Shared.LocalState.LocalParticipantInfo)
local remotes = ReplicatedStorage.Remotes

local function ViewCorpse(player: Model | Player): ()
	CreateRadarPoint.RemoveRadarPoints("CallToCorpse" .. player.Name)
	local corpse = LocalParticipantInfo.GetParticipant(player.Name).Corpse()
	if not corpse then
		corpse = remotes.ClientServer.GetCorpseInfo:InvokeServer(player, Crouch.IsCrouching())
		if not corpse then
			return
		end
	end

	assert(corpse)

	CorpseInfo(corpse)
end

return ViewCorpse