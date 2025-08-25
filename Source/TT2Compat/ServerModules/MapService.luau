local ServerScriptService = game:GetService("ServerScriptService")
local RoundHandler = require(ServerScriptService.RoundHandler)

local module = {}

function module.SpawnPlayer(self, player: Player, cframe: CFrame): ()
	local participant = RoundHandler.GetRound():GetParticipant(player.Name)
	if not participant then
		return
	end

	participant:MoveToSpawn(cframe)
end

return module