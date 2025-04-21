local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ControlManager = require(script.Parent.ControlManager)
local CorpseInfo = require(script.Parent.CorpseInfo)
local LocalRoundInfo = require(script.Parent.LocalRoundInfo)

local function ViewCorpse(player: Model | Player): ()
	local corpseValue = LocalRoundInfo.PlayerCorpses()[player.Name]
	local corpse = if corpseValue then corpseValue() else nil
	if not corpse then
		corpse = ReplicatedStorage.ClientServer.GetCorpseInfo:InvokeServer(player, ControlManager.IsActionActive("Crouch"))
		if not corpse then
			return
		end
	end

	assert(corpse)

	CorpseInfo(corpse)
end

return ViewCorpse