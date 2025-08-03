local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local GamemodeNameRemap = require(ReplicatedStorage.Compat.GamemodeNameRemap)
local Types = require(ReplicatedStorage.Shared.RoundRule.Types)
local RoundHandler = require(ServerScriptService.RoundHandler)

local module = {}

module.Gamemode = nil :: (Types.Gamemode & {Credits: {}})?

local function onPlayerAdded(player: Player): ()
	if module.Gamemode then
		module.Gamemode.Credits[player] = math.huge -- So that when a traitor node is checking if they have enough credits, they do.
	end
end

RoundHandler.Round:Connect(function(round)
	module.GamemodeId = GamemodeNameRemap(round.Gamemode.Name)

	local gamemode = round.Gamemode :: Types.Gamemode & {Credits: {}}
	module.Gamemode = gamemode
	gamemode.Credits = {}

	for _, v in Players:GetPlayers() do
		onPlayerAdded(v)
	end
end, true)

Players.PlayerAdded:Connect(onPlayerAdded)

-- And we don't need to listen for PlayerRemoving because the credits table is reset every round

return module