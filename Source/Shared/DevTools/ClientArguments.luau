local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlaceIDs = require(ReplicatedStorage.Shared.Places.PlaceIDs)
local Commands = require(script.Parent.Commands)

local ClientArguments = {}

function ClientArguments.IsValidType(argument: string, type: Commands.ArgumentType): string?
	if type == "place" then
		return if PlaceIDs[argument] then nil else "place"
	elseif type == "number" then
		return if tonumber(argument) then nil else "number"
	elseif type == "optional" then
		return if argument == "nil" then nil else "'nil'"
	elseif type == "exact_player" then
		return if Players:FindFirstChild(argument) then nil else "exact player"
	elseif typeof(type) == "table" and type.kind == "literal" then
		return if argument == type.literal then nil else `'{type.literal}'`
	end

	return "unknown"
end

function ClientArguments.IsValidArgument(command: Commands.Command, argument: string, index: number): string?
	local types = command.Types[index]
	if not types and command.Arguments[#command.Arguments] ~= "..." then
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
		local result = ClientArguments.IsValidType(argument, type :: Commands.ArgumentType)
		if not result then
			-- As soon as one matches, we are clear of any errors on this argument
			return nil
		end

		table.insert(failedTypes, result)
	end

	return "Expected " .. table.concat(failedTypes, ", ")
end

return ClientArguments