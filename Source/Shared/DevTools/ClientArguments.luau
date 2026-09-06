local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalRoundInfo = require(ReplicatedStorage.Shared.LocalState.LocalRoundInfo)
local Arguments = require(script.Parent.Arguments)
local Commands = require(script.Parent.Commands)

local ClientArguments = {}

function ClientArguments.IsValidType(argument: string, type: Arguments.ArgumentType): string?
	local processedString = Arguments.String(argument)
	if type == "any" or type == "string" then
		return nil
	elseif type == "place" then
		return if Arguments.Place(processedString) then nil else "place"
	elseif type == "number" then
		return if Arguments.Number(argument) then nil else "number"
	elseif type == "exact_player" then
		return if Arguments.ExactPlayer(argument) then nil else "exact player"
	elseif typeof(type) == "table" and type.kind == "literal" then
		return if processedString == type.literal then nil else `'{type.literal}'`
	elseif type == "boss" then
		const map = LocalRoundInfo.Map()
		return if map and Arguments.Boss(map, processedString) then nil else "boss"
	elseif type == "item" then
		const map = LocalRoundInfo.Map()
		const gamemode = LocalRoundInfo.Gamemode()
		return if map and gamemode and Arguments.Item(gamemode, map, processedString) then nil else "item"
	elseif type == "gamemode" then
		return if Arguments.Gamemode(processedString) then nil else "gamemode"
	elseif type == "map" then
		return if Arguments.Map(processedString) then nil else "map"
	elseif type == "players" then
		return if Arguments.Players(Players.LocalPlayer, processedString) then nil else "players"
	elseif type == "role" then
		const gamemode = LocalRoundInfo.Gamemode()
		return if gamemode and Arguments.Role(gamemode, processedString) then nil else "role"
	end

	return "unknown"
end

function ClientArguments.IsValidArgument(command: Commands.Command, argument: string, index: number): string?
	local types = command.Types[index]
	if not types and command.Arguments[#command.Arguments] ~= Arguments.Variadic then
		return "Expected at most " .. #command.Arguments .. " arguments"
	elseif not types then
		types = command.Types[#command.Arguments]
		if not types then
			return nil
		end
	end

	assert(types)

	if table.find(types, "string") or table.find(types, "any") then
		return nil -- Any string is valid input. Obviously any any is also valid
	end

	local failedTypes: {string} = {}

	for _, type in types do
		local result = ClientArguments.IsValidType(argument, type :: Arguments.ArgumentType)
		if not result then
			-- As soon as one matches, we are clear of any errors on this argument
			return nil
		end

		table.insert(failedTypes, result)
	end

	return "Expected " .. table.concat(failedTypes, ", ")
end

return ClientArguments