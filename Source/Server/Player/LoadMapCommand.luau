local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local Map = require(ReplicatedStorage.Shared.RoundRule.Map)
local RoundHandler = require(ServerScriptService.RoundHandler)
local Replication = require(ReplicatedStorage.Shared.RoundRule.Replication)

ServerScriptService.CustomMaps.GetMapModule.OnInvoke = function()
	return Map
end

local LoadMap = require(ServerScriptService.CustomMaps.LoadMap) -- We do need to load after binding OnInvoke otherwise it just hangs indefinitely
local function LoadMapCommand(player: Player): ()
	player.Chatted:Connect(function(message: string, target: Player?): ()
		if message:split(" ")[1] ~= "!loadmap" or target then
			return
		end

		local id = tonumber(message:split(" ")[2])
		if not id then
			return Replication.SendMessage("All", "Invalid or missing map ID", "Chat")
		end

		local result = LoadMap(id)
		Replication.SendMessage("All", if typeof(result) == "string" then result else "Loaded map: " .. result.Name, "Chat")

		if typeof(result) == "string" then
			return
		end
		result.Parent = ServerStorage
		RoundHandler.GetRound():LoadMap(result)
	end)
end

return LoadMapCommand