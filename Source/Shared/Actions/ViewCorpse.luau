local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ControlManager = require(ReplicatedStorage.Shared.Controls.ControlManager)
local CorpseInfo = require(ReplicatedStorage.Shared.Interface.GameState.CorpseInfo)
local LocalRoundInfo = require(ReplicatedStorage.Shared.LocalState.LocalRoundInfo)

local remotes = ReplicatedStorage.Remotes

local function ViewCorpse(player: Model | Player): ()
	local corpse = LocalRoundInfo.GetPlayerCorpse(player.Name)
	if not corpse then
		corpse = remotes.ClientServer.GetCorpseInfo:InvokeServer(player, ControlManager.IsActionActive("Crouch"))
		if not corpse then
			return
		end
	end

	assert(corpse)

	CorpseInfo(corpse)
end

return ViewCorpse