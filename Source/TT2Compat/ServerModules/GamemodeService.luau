local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local GamemodeNameRemap = require(ReplicatedStorage.Compat.GamemodeNameRemap)
local Types = require(ReplicatedStorage.Shared.RoundRule.Types)
local RoundHandler = require(ServerScriptService.RoundHandler)

local module = {}

RoundHandler.Round:Connect(function(round)
	module.GamemodeId = GamemodeNameRemap(round.Gamemode.Name)
	module.Gamemode = round.Gamemode :: Types.Gamemode & {Credits: {}}
	module.Gamemode.Credits = {}
end, true)

return module