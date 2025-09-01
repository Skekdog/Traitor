local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RoundHandler = require(ServerScriptService.RoundHandler)
local Types = require(ReplicatedStorage.Shared.RoundRule.Types)

local function GetRound(): Types.Round
	return RoundHandler.Round()
end

return GetRound