local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.RoundRule.Types)
local Commands = require(script.Parent.Commands)
local IsAdmin = require(script.Parent.IsAdmin)

local module = {}

function module.Execute(player: Player, round: Types.Round, command: string): string
	if not IsAdmin(player) then
		return "You are not an admin!"
	end
	
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