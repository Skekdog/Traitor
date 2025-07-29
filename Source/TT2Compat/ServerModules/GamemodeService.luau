local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Types = require(ReplicatedStorage.Shared.RoundRule.Types)
local RoundHandler = require(ServerScriptService.RoundHandler)

local module = {}

RoundHandler.Round:Connect(function(round)
	module.GamemodeId = round.Gamemode.Name
	module.Gamemode = round.Gamemode :: Types.Gamemode & {Credits: {}}
	module.Gamemode.Credits = {}
end, true)

return module