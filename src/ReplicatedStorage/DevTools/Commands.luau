local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local TeleportService = game:GetService("TeleportService")
local Items = require(ReplicatedStorage.GameDefinition.Items.Items)
local PlaceIDs = require(ReplicatedStorage.PlaceIDs)
local Types = require(ReplicatedStorage.RoundRule.Types)

export type BaseCommand = {
	Name: string,
	Description: string,
	Arguments: {string},
}

export type ClientCommand = BaseCommand & {
	Environment: "Client",
	Execute: (player: Player, args: Args) -> string,
}

export type ServerCommand = BaseCommand & {
	Environment: "Server",
	Execute: (executor: Player, round: Round, args: Args) -> string,
}

export type Command = ClientCommand | ServerCommand

type Round = Types.Round
type Args = {string?}

local WHITESPACE_SUBSTITUTE = "-"

local function processStringArgument(str: string?): string?
	return if str then str:gsub(WHITESPACE_SUBSTITUTE, " ") else nil
end

local function processNumberArgument(str: string?): number?
	return if str then tonumber(str) else nil
end

local function processPlayerArgument(executor: Player, str: string?): {Player}?
	if not str then
		return {executor}
	end

	if str == "@a" then
		return Players:GetPlayers()
	elseif str == "@s" then
		return {executor}
	elseif str == "@r" then
		local players = Players:GetPlayers()
		return {players[math.random(#players)]}
	end

	local player = Players:FindFirstChild(str)
	if player and player:IsA("Player") then
		return {player}
	end

	return nil
end

local function getPlayersString(players: {Player}): string
	local ret = ""
	for _, player in players do
		ret ..= `{player.Name}{if player ~= players[#players] then ", " else ""}`
	end
	return ret
end

local endRoundParams: {any}?
local normalEndRound: (...any) -> ()

local function disabledEndRound(...: any): ()
    endRoundParams = {...}
end

local function toggleVictory(_: any, round: Types.Round): string
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
	Environment = "Client" :: "Client",
	Arguments = {},
	Execute = function()
		local ret = "Players can be specified using name, @s, @a, or @r.\nCommands:\n"

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

module.luauserver = {
	Name = "luauserver",
	Description = "Executes Luau code server-side. Includes globals: round, cmds, items, players",
	Environment = "Server" :: "Server",
	Arguments = {"code"},
	Execute = function(_, round: Round, args: Args)
		local code = table.concat(args, " ")
		
		local func = loadstring(code, "")
		if not func then
			return "ERROR: Invalid syntax."
		end

		local env = getfenv()
		env["round"] = round
		env["cmds"] = module
		env["items"] = Items
		env["players"] = Players
		setfenv(func, env)

		local success, result = pcall(func)
		if not success then
			return `ERROR: {result}.`
		end

		return tostring(result) or ""
	end
}

module.noclip = {
	Name = "noclip",
	Description = "Toggles noclip on/off",
	Environment = "Client" :: "Client",
	Arguments = {},
	Execute = function(player: Player, args: Args)
		local NoClip = require(script.Parent.NoClip)
		local enabled = NoClip.Enable()
		return `Noclip {if enabled then "enabled" else "disabled"}.`
	end
}

module.freecam = {
	Name = "freecam",
	Description = "Toggles freecam on/off",
	Environment = "Client" :: "Client",
	Arguments = {},
	Execute = function(player: Player, args: Args)
		local Freecam = require(ReplicatedStorage.Freecam)
		local enabled = Freecam.ToggleFreecam()
		return `Freecam {if enabled then "enabled" else "disabled"}.`
	end
}

module.teleportplace = {
	Name = "teleportplace",
	Description = "Teleports specified players to the specified place. Available named places: Imperium, MainPlace, TestPlace",
	Environment = "Server" :: "Server",
	Arguments = {"place name / id", "players"},
	Execute = function(executor: Player, round: Round, args: Args)
		local asId = processNumberArgument(args[1])
		local asName = processStringArgument(args[1])
		local place = if asId then asId else PlaceIDs[asName]

		if not place then
			return "Place not found."
		end

		local players = processPlayerArgument(executor, args[2])
		if not players then
			return `Player {args[2]} not found.`
		end

		TeleportService:TeleportAsync(place, players)
		return `Teleporting {getPlayersString(players)} to {place}.`
	end
}

module.setrole = {
	Name = "setrole",
	Description = "Sets the roles of players",
	Environment = "Server" :: "Server",
	Arguments = {"role name", "players"},
	Execute = function(executor: Player, round: Round, args: Args)
		local players = processPlayerArgument(executor, args[2])
		if not players then
			return `Player {args[2]} not found.`
		end

		local roleName = processStringArgument(args[1])
		if not roleName then
			return "Missing argument 1 role name."
		end

		for _, player in players do
			local participant = round:GetParticipant(player.Name)
			if not participant then
				continue
			end

			local success, result = pcall(round.GetRoleFromRoleName, round, roleName)
			if not success then
				return `Role {roleName} not found.`
			end

			participant:SetRole(result.Definition)
		end

		return `Set roles of {getPlayersString(players)} to {roleName}.`
	end
}

module.kill = {
	Name = "kill",
	Description = "Kills the specified players",
	Environment = "Server" :: "Server",
	Arguments = {"player name"},
	Execute = function(executor: Player, round: Round, args: Args)
		local players = processPlayerArgument(executor, args[1])
		if not players then
			return `Player {args[1]} not found.`
		end

		for _, player in players do
			local participant = round:GetParticipant(player.Name)
			if not participant then
				continue
			end

			participant:TryTakeDamage({
				Amount = math.huge,
				Source = "Other"
			})
		end

		return `Killed {getPlayersString(players)}.`
	end
}

module.endround = {
	Name = "endround",
	Description = "Ends the current round with a victory for the specified role",
	Environment = "Server" :: "Server",
	Arguments = {"role name"},
	Execute = function(_, round: Round, args: Args)
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
				toggleVictory(nil, round)
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
	Environment = "Server" :: "Server",
	Arguments = {},
	Execute = function(_, round: Types.Round)
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
	Environment = "Server" :: "Server",
	Arguments = {},
	Execute = toggleVictory
}

module.restart = {
	Name = "restart",
	Description = "Restarts the server",
	Environment = "Server" :: "Server",
	Arguments = {},
	Execute = function()
		local ServerScriptService = game:GetService("ServerScriptService")

		local RestartServer = require(ServerScriptService.RestartServer)

		RestartServer(5)
		return "Server restarting..."
	end
}

module.map = {
	Name = "map",
	Description = "Changes the map",
	Environment = "Server" :: "Server",
	Arguments = {"map name"},
	Execute = function(_, round: Round, args: Args)
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
	Description = "Gives an item to players",
	Environment = "Server" :: "Server",
	Arguments = {"item name", "players"},
	Execute = function(executor: Player, round: Round, args: {string?})
		local players = processPlayerArgument(executor, args[2])
		if not players then
			return `Player {args[2]} not found.`
		end

		local itemName = processStringArgument(args[1])
		if not itemName then
			return "Missing argument 1 item name."
		end

		for _, player in players do
			local participant = round:GetParticipant(player.Name)
			if not participant then
				continue
			end

			local item = round:GetItemDefinition(itemName)
			if not item then
				return `Item {itemName} not found.`
			end
			participant:GiveItemFromItemDefinition(item)
		end

		return `Gave {itemName} to {getPlayersString(players)}.`
	end
}

module.givecredits = {
	Name = "givecredits",
	Description = "Gives credits to players",
	Environment = "Server" :: "Server",
	Arguments = {"amount", "players"},
	Execute = function(executor: Player, round: Round, args: Args)
		local players = processPlayerArgument(executor, args[2])
		if not players then
			return `Player {args[2]} not found.`
		end

		local amount = processNumberArgument(args[1])
		if not amount then
			return "Invalid argument 1 amount."
		end

		for _, player in players do
			local participant = round:GetParticipant(player.Name)
			if not participant then
				continue
			end

			participant:AddCredits(amount)
		end

		return `Gave {amount} credits to {getPlayersString(players)}.`
	end
}

return module