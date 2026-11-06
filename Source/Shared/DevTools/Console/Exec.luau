local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.API.Types)
local Lexer = require(ReplicatedStorage.Shared.DevTools._Console.Lexer)
local Parser = require(ReplicatedStorage.Shared.DevTools._Console.Parser)
local Commands = require(script.Parent.Commands)
local RelaxedPermissions = require(script.Parent.RelaxedPermissions)
local IsAdmin = require(script.Parent.IsAdmin)

local module = {}

export type CommandSequence = {
	Command: Commands.Command?,
	ParsedName: string,
	Args: {string},
}

local function getCommandSequence(input: string): {CommandSequence}
	local parseResult = Parser.Parse(input, Lexer.Lex(input))
	if not parseResult.ok then
		return {}
	end

	local sequence: {CommandSequence} = {}
	for _, token in parseResult.tokens do
		if token.kind == "COMMAND" then
			table.insert(sequence, {
				Command = Commands[token.parsed_content:lower()],
				ParsedName = token.parsed_content,
				Args = {},
			})
		else
			local command = assert(sequence[#sequence])
			table.insert(command.Args, token.parsed_content)
		end
	end

	return sequence
end

function module.ClientExecute(input: string): {string}
	local commands = getCommandSequence(input)

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
	local commands = getCommandSequence(input)

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