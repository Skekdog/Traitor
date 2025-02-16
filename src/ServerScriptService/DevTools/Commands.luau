local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local Items = require(ReplicatedStorage.GameDefinition.Items)
local RestartServer = require(ServerScriptService.RestartServer)
local Types = require(ReplicatedStorage.RoundRule.Types)

export type Command = {
	Name: string,
	Description: string,
	Arguments: {string},
	Execute: (round: Types.Round, args: {string?}) -> string,
}

local WHITESPACE_SUBSTITUTE = "-"

local function processStringArgument(str: string?): string?
	return if str then str:gsub(WHITESPACE_SUBSTITUTE, " ") else nil
end

local function processNumberArgument(str: string?): number?
	return if str then tonumber(str) else nil
end

local endRoundParams: {any}?
local normalEndRound: (...any) -> ()

local function disabledEndRound(...: any): ()
    endRoundParams = {...}
end

local function toggleVictory(round: Types.Round): string
    if not round:IsInProgress() then
        return "Round is not in progress."
    end

    if round.EndRound ~= disabledEndRound then
        endRoundParams = nil
        normalEndRound = round.EndRound
        round.EndRound = disabledEndRound
        return "Victory disabled."
    else
        round.EndRound = normalEndRound
        if endRoundParams then
            normalEndRound(table.unpack(endRoundParams))
        end
        return "Victory enabled."
    end
end

local module: {[string]: Command} = {}

module.help = {
	Name = "help",
	Description = "Lists all commands",
	Arguments = {},
	Execute = function()
		local ret = "Commands:\n"

		for _, v in module do

			local args = if #v.Arguments == 0 then "" else " "
			for i, arg in v.Arguments do
				args ..= `<{arg}>{if i < #v.Arguments then " " else ""}`
			end

			ret ..= `{v.Name}{args}: {v.Description}\n`
		end

		ret = ret:sub(1, -2)

		return ret
	end
}

module.echo = {
	Name = "echo",
	Description = "Returns the provided input.",
	Arguments = {"input"},
	Execute = function(round, args)
		return table.concat(args, " ")
	end
}

module.luau = {
	Name = "luau",
	Description = "Executes Luau code. Includes globals: round, cmds, items",
	Arguments = {"code"},
	Execute = function(round, args)
		local code = table.concat(args, " ")
		
		local func = loadstring(code, "")
		if not func then
			return "ERROR: Invalid syntax."
		end

		local env = getfenv()
		env["round"] = round
		env["cmds"] = module
		env["items"] = Items
		setfenv(func, env)

		local success, result = pcall(func)
		if not success then
			return `ERROR: {result}.`
		end

		return tostring(result) or ""
	end
}

module.setrole = {
	Name = "setrole",
	Description = "Sets the role of a player",
	Arguments = {"player name", "role name"},
	Execute = function(round, args)
		local playerName = processStringArgument(args[1])
		if not playerName then
			return "Missing argument 1 player name."
		end

		local roleName = processStringArgument(args[2])
		if not roleName then
			return "Missing argument 2 role name."
		end

		local participant = round:GetParticipant(playerName)
		if not participant then
			return `Participant {playerName} not found.`
		end

		local role = round:GetRoleFromRoleName(roleName)
		if not role then
			return `Role {roleName} not found.`
		end

		participant:SetRole(role.Definition)

		return `Set {playerName}'s role to {roleName}.`
	end
}

module.kill = {
	Name = "kill",
	Description = "Kills the specified player",
	Arguments = {"player name"},
	Execute = function(round, args)
		local playerName = processStringArgument(args[1])
		if not playerName then
			return "Missing argument 1 player name."
		end

		local participant = round:GetParticipant(playerName)
		if not participant then
			return `Participant {playerName} not found.`
		end

		participant:TryTakeDamage({
			Amount = math.huge,
			Source = "Other"
		})

		return `Killed {playerName}.`
	end
}

module.endround = {
	Name = "endround",
	Description = "Ends the current round with a victory for the specified role",
	Arguments = {"role name"},
	Execute = function(round, args)
		local roleName = args[1]
		if not roleName then
			return "Missing argument 1 role name."
		end

		if not round:IsInProgress() then
			return "Round is not in progress."
		end

		local success, err = pcall(function()
			round:EndRound(round:GetRoleFromRoleName(roleName))
			if round.EndRound == disabledEndRound then
				toggleVictory(round)
			end
		end)

		if success then
			return "Round ended."
		else
			return `Failed to end round: {err}.`
		end
	end
}

module.pause = {
	Name = "pause",
	Description = "Pauses or unpauses the round",
	Arguments = {},
	Execute = function(round)
		if round:GetRoundPhase() == "Intermission" or round:GetRoundPhase() == "Waiting" then
			return "Cannot pause during intermission or waiting phase."
		end
	
		round:PauseRound(not round:GetIsRoundPaused())
		return if round:GetIsRoundPaused() then "Round paused." else "Round unpaused."
	end
}

module.togglevictory = {
	Name = "togglevictory",
	Description = "Enables or disables victory",
	Arguments = {},
	Execute = toggleVictory
}

module.restart = {
	Name = "restart",
	Description = "Restarts the server",
	Arguments = {},
	Execute = function(round)
		RestartServer(5)
		return "Server restarting..."
	end
}

module.map = {
	Name = "map",
	Description = "Changes the map",
	Arguments = {"map name"},
	Execute = function(round, args)
		local mapName = processStringArgument(args[1])
		if not mapName then
			return "Missing argument 1 map name."
		end

		local map = ServerStorage.Maps:FindFirstChild(mapName)
		if not map then
			return `Map {mapName} not found.`
		end
		assert(map:IsA("ModuleScript"))
		round:LoadMap(map)

		return `Map changed to {mapName}.`
	end
}

module.giveitem = {
	Name = "giveitem",
	Description = "Gives an item to a player",
	Arguments = {"player name", "item name"},
	Execute = function(round, args)
		local playerName = processStringArgument(args[1])
		if not playerName then
			return "Missing argument 1 player name."
		end

		local itemName = processStringArgument(args[2])
		if not itemName then
			return "Missing argument 2 item name."
		end

		local participant = round:GetParticipant(playerName)
		if not participant then
			return `Participant {playerName} not found.`
		end

		local item = round:GetItemDefinition(itemName)
		if not item then
			return `Item {itemName} not found.`
		end
		participant:GiveItemFromItemDefinition(item)

		return `Gave {itemName} to {playerName}.`
	end
}

module.givecredits = {
	Name = "givecredits",
	Description = "Gives credits to a player",
	Arguments = {"player name", "amount"},
	Execute = function(round, args)
		local playerName = processStringArgument(args[1])
		if not playerName then
			return "Missing argument 1 player name."
		end

		local amount = processNumberArgument(args[2])
		if not amount then
			return "Invalid argument 2 amount."
		end

		local participant = round:GetParticipant(playerName)
		if not participant then
			return `Participant {playerName} not found.`
		end

		participant:AddCredits(amount)

		return `Gave {amount} credits to {playerName}.`
	end
}

return module