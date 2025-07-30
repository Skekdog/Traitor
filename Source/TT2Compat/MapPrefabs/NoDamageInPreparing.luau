local ServerScriptService = game:GetService("ServerScriptService")
local RoundHandler = require(ServerScriptService.RoundHandler)

local function NoDamageInPreparing(): boolean
	local round = RoundHandler.GetRound()
	return not round:IsPreGame()
end

return NoDamageInPreparing