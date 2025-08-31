local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.Shared.RoundRule.Types)
local Commands = require(script.Parent.Commands)
local RelaxedPermissions = require(script.Parent.RelaxedPermissions)
local IsAdmin = require(script.Parent.IsAdmin)

local module = {}

export type ParsedCommand = {
	Command: Commands.Command?,
	ParsedName: string,
	Args: {string},
}

function module.ParseCommand(command: string): ParsedCommand
	local split = command:split(" ")
	local cmdName = split[1]

	local args = {}
	table.move(split, 2, #split, 1, args)

	local cmd = Commands[cmdName]

	return {
		Command = cmd,
		ParsedName = cmdName,
		Args = args,
	}
end

function module.ClientExecute(command: string): string
	local parsed = module.ParseCommand(command)
	if not parsed.Command then
		return `Command {parsed.ParsedName} not found.`
	end

	if not IsAdmin(Players.LocalPlayer) then
		if not parsed.Command.HasRelaxedPermissions or (parsed.Command.HasRelaxedPermissions and not RelaxedPermissions.HasRelaxedPermissions(Players.LocalPlayer)) then
			return "You do not have permission to run this command."
		end
	end

	if parsed.Command.Environment == "Client" then
		local _, result = pcall(parsed.Command.Execute, Players.LocalPlayer, parsed.Args)
		return result
	end

	return ReplicatedStorage.Remotes.ClientServer.Exec:InvokeServer(command)
end

function module.ServerExecute(player: Player, round: Types.Round, command: string): string
	local parsed = module.ParseCommand(command)
	if not parsed.Command then
		return `Command {parsed.Args[1]} not found.`
	end

	if not IsAdmin(player) then
		if not parsed.Command.HasRelaxedPermissions or (parsed.Command.HasRelaxedPermissions and not RelaxedPermissions.HasRelaxedPermissions(player)) then
			return "You do not have permission to run this command."
		end
	end

	if parsed.Command.Environment ~= "Server" then
		return `Command {parsed.Command.Name} is not a server command.`
	end

	local _, result = pcall(parsed.Command.Execute, player, round, parsed.Args)
	return result
end

return module