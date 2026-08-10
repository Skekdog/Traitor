local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local GetDisplayName = require(ReplicatedStorage.Shared.RoundRule.Common.GetDisplayName)
local SharedTypes = require(ReplicatedStorage.Shared.SharedTypes)
local RoundHandler = require(ServerScriptService.RoundHandler)

type ServerInfo = SharedTypes.ServerInfo

const currentServerInfo: ServerInfo = {
	Players = {},
	Capacity = Players.MaxPlayers,
	Gamemode = "",
	Map = "",

	PlaceId = 0
}

local function updateServerInfo(serverInfo: ServerInfo): ()
	table.clear(serverInfo.Players)
	for _, player in Players:GetPlayers() do
		table.insert(serverInfo.Players, player.UserId)
	end

	local round = RoundHandler.GetRound()

	serverInfo.Gamemode = GetDisplayName(round.Gamemode)
	serverInfo.Map = GetDisplayName(round:GetMap())
	serverInfo.PlaceId = game.PlaceId
end

const ServerInfo = {}

function ServerInfo.Get(): ServerInfo
	updateServerInfo(currentServerInfo)
	return currentServerInfo
end

return table.freeze(ServerInfo)