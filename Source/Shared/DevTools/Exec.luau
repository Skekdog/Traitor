local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.API.Types)
local Commands = require(script.Parent.Commands)
local RelaxedPermissions = require(script.Parent.RelaxedPermissions)
local IsAdmin = require(script.Parent.IsAdmin)

local module = {}

export type ParsedCommand = {
	Command: Commands.Command?,
	ParsedName: string,
	Args: {string},
}

function module.ParseCommands(input: string): {ParsedCommand}
	local parsedCommands: {ParsedCommand} = {}

	local commands = input:split(";")
	for _, command in commands do
		if command == "" then
			continue
		end

		local split = command:split(" ")

		local splitFix: {string} = {}
		for _, part in split do
			if part ~= "" then
				table.insert(splitFix, part)
			end
		end

		local cmdName = splitFix[1]

		local args = {}
		table.move(splitFix, 2, #splitFix, 1, args)

		local cmd = Commands[cmdName]

		table.insert(parsedCommands, {
			Command = cmd,
			ParsedName = cmdName,
			Args = args,
		})
	end

	return parsedCommands
end

function module.ClientExecute(input: string): {string}
	local commands = module.ParseCommands(input)

	local output: {string} = {}

	for _, command in commands do
		if not command.Command then
			table.insert(output, `Command {command.ParsedName} not found.`)

			-- Note: we early return here intentionally due to a hard error with the command.
			return output
		end

		if not IsAdmin(Players.LocalPlayer) then
			if not command.Command.HasRelaxedPermissions or (command.Command.HasRelaxedPermissions and not RelaxedPermissions.HasRelaxedPermissions(Players.LocalPlayer)) then
				table.insert(output, "You do not have permission to run this command.")
				return output
			end
		end

		if command.Command.Environment == "Client" then
			local _, result = pcall(command.Command.Execute, Players.LocalPlayer, command.Args)
			table.insert(output, result)
		end
	end

	local serverOutput = ReplicatedStorage.Remotes.ClientServer.Exec:InvokeServer(input)
	table.move(serverOutput, 1, #serverOutput, #output + 1, output)

	return output
end

function module.ServerExecute(player: Player, round: Types.Round, input: string): {string}
	local commands = module.ParseCommands(input)

	local output: {string} = {}

	for _, command in commands do
		if not command.Command then
			table.insert(output, `Command {command.ParsedName} not found.`)
			return output
		end

		if command.Command.Environment ~= "Server" then
			-- Client sends entire input string. This includes client-side commands, so we just skip them.
			continue
		end

		if not IsAdmin(player) then
			if not command.Command.HasRelaxedPermissions or (command.Command.HasRelaxedPermissions and not RelaxedPermissions.HasRelaxedPermissions(player)) then
				table.insert(output, "You do not have permission to run this command.")
				return output
			end
		end

		local _, result = pcall(command.Command.Execute, player, round, command.Args)
		table.insert(output, result)
	end

	return output
end

return table.freeze(module)