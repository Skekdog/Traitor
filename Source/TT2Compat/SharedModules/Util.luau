local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Types = require(ReplicatedStorage.Shared.RoundRule.Types)

local module = {}

function module.GetCharactersArray(position: Vector3, distance: number): {Model}
	local characters: {Model} = {}
	for _, v in Players:GetPlayers() do
		if v.Character and v:DistanceFromCharacter(position) < distance then
			table.insert(characters, v.Character)
		end
	end
	return characters
end

function module.GetPlayerFromInstance(instance: BasePart | Model): Player?
	local char: Model?
	if instance:IsA("BasePart") then
		char = instance:FindFirstAncestorOfClass("Model")
	else
		char = instance
	end

	if not char then
		return nil
	end

	return Players:GetPlayerFromCharacter(char)
end

function module.GetPropFromInstance(instance: BasePart): Types.Prop?
	local RoundHandler = require(ServerScriptService.RoundHandler)
	local round = RoundHandler.GetRound()
	return round:GetProp(instance) :: Types.Prop
end

function module.GetItemFromInstance(instance: BasePart): Types.AnyItem?
	local RoundHandler = require(ServerScriptService.RoundHandler)
	local round = RoundHandler.GetRound()
	return round:GetItem(instance)
end

function module.GetAlivePlayers(): {Player}
	local players: {Player} = {}

	for _, v in Players:GetPlayers() do
		if v.Character then
			table.insert(players, v)
		end
	end

	return players
end

return module