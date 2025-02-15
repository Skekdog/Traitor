local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.RoundRule.Types)
local Commands = require(script.Parent.Commands)

local module = {}

function module.Execute(round: Types.Round, command: string): string
	local split = command:split(" ")
	local cmdName = split[1]

	local args = {}
	table.move(split, 2, #split, 1, args)

	local cmd = Commands[cmdName]
	if not cmd then
		return `Command {cmdName} not found.`
	end

	return cmd.Execute(round, args)
end

return module