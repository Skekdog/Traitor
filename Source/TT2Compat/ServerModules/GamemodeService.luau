local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local GamemodeNameRemap = require(ReplicatedStorage.Compat.GamemodeNameRemap)
local RoundHandler = require(ServerScriptService.RoundHandler)

local Credits = {}
local Gamemode = {Credits = Credits}
local GamemodeService = {Gamemode = Gamemode}

setmetatable(Gamemode, {
	__index = function(self, index: unknown): any
		if typeof(index) ~= "Instance" or not index:IsA("Player") then
			return nil
		end

		local participant = RoundHandler.GetRound():GetParticipant(index.Name)
		if not participant then
			return nil
		end

		return participant:GetCredits()
	end
})

setmetatable(GamemodeService, {
	__index = function(self, index: unknown): any
		local round = RoundHandler.GetRound()
		if index == "GamemodeId" then
			return GamemodeNameRemap(round.Gamemode.Name)
		end
		return nil
	end
})

return GamemodeService