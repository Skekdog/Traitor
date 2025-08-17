local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local TeleportService = game:GetService("TeleportService")
local Items = require(ReplicatedStorage.Shared.GameDefinition.Items.Items)
local PlaceIDs = require(ReplicatedStorage.Shared.Util.PlaceIDs)
local Types = require(ReplicatedStorage.Shared.RoundRule.Types)
local GetPrimaryPart = require(ReplicatedStorage.Shared.RoundRule.Common.GetPrimaryPart)
local Map = require(ReplicatedStorage.Shared.RoundRule.Map)

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

    if round.Finish ~= disabledEndRound then
        endRoundParams = nil
        normalEndRound = round.Finish
        round.Finish = disabledEndRound
        return "Victory disabled."
    else
        round.Finish = normalEndRound
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

module.xray = {
	Name = "xray",
	Description = "Turns all static map parts semi-transparent.",
	Environment = "Client" :: "Client",
	Arguments = {},

	Execute = function(): string
		local LocalRoundInfo = require(ReplicatedStorage.Shared.LocalState.LocalRoundInfo)
		local map = LocalRoundInfo.Map()

		if not map then
			return "No map loaded."
		end

		local enabled = not (map.Static:GetAttribute("XRayEnabled") :: boolean?)
		map.Static:SetAttribute("XRayEnabled", enabled)

		for _, instance in map.Static:GetDescendants() do
			if not instance:IsA("BasePart") and not instance:IsA("Texture") or instance:HasTag("Prop") then
				continue
			end

			local part = instance :: BasePart -- typechecker kludge

			if enabled then
				part:SetAttribute("OriginalTransparency", instance.Transparency)
				part.Transparency = 0.75
			else
				local originalTransparency = part:GetAttribute("OriginalTransparency") :: number?
				if originalTransparency then
					part.Transparency = originalTransparency
				end
			end
		end

		return `XRay {if enabled then "enabled" else "disabled"}.`
	end
}

module.showbounds = {
	Name = "showbounds",
	Description = "Toggles showing of map bounds",
	Environment = "Client" :: "Client",
	Arguments = {},
	Execute = function(): string
		local LocalRoundInfo = require(ReplicatedStorage.Shared.LocalState.LocalRoundInfo)
		local map = LocalRoundInfo.Map()

		if not map then
			return "No map loaded."
		end

		local enabled = not (map.Static:GetAttribute("ShowBounds") :: boolean?)
		map.Static:SetAttribute("ShowBounds", enabled)

		for _, instance in map.Static:GetDescendants() do
			if not instance:IsA("BasePart") or instance:HasTag("Prop") then
				continue
			end

			instance.Material = Enum.Material.ForceField
			instance.Color = Color3.new(1, 0, 1)
			instance.Transparency = if enabled then 0 else 1
		end

		return `ShowBounds {if enabled then "enabled" else "disabled"}.`
	end,
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
		local Freecam = require(ReplicatedStorage.Shared.Camera.Freecam)
		local enabled = Freecam.ToggleFreecam()
		return `Freecam {if enabled then "enabled" else "disabled"}.`
	end
}

module.thirdperson = {
	Name = "thirdperson",
	Description = "Toggles thirdperson on/off",
	Environment = "Client" :: "Client",
	Arguments = {},
	Execute = function(player: Player, args: Args)
		player.CameraMode = if player.CameraMode == Enum.CameraMode.Classic then Enum.CameraMode.LockFirstPerson else Enum.CameraMode.Classic
		return `Third person {if player.CameraMode == Enum.CameraMode.Classic then "enabled" else "disabled"}.`
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

module.teleport = {
	Name = "teleport",
	Description = "Teleports players to another player.",
	Environment = "Server" :: "Server",
	Arguments = {"to", "targets"},
	Execute = function(executor: Player, round: Round, args: Args): string
		local to = processPlayerArgument(executor, args[1])
		if not to then
			return `Player {args[1]} not found.`
		end

		local targets = processPlayerArgument(executor, args[2])
		if not targets then
			return `Player {args[2]} not found.`
		end

		local toChar = to[1].Character
		if not toChar then
			return `Player {to[1].Name} has no character.`
		end

		for _, target in targets do
			local char = target.Character
			if char then
				local root = char.PrimaryPart
				if root then
					root.AssemblyLinearVelocity = Vector3.zero
				end
				char:PivotTo(toChar:GetPivot())
			end
		end

		return `Teleported {getPlayersString(targets)} to {to[1].Name}.`
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

module.setfreekill = {
	Name = "setfreekill",
	Description = "Sets free kill reason for the specified players",
	Environment = "Server" :: "Server",
	Arguments = {"reason / nil", "players"},
	Execute = function(executor: Player, round: Round, args: Args): string
		local players = processPlayerArgument(executor, args[2])
		if not players then
			return `Player {args[2]} not found.`
		end

		local reason = processStringArgument(args[1])

		for _, player in players do
			local participant = round:GetParticipant(player.Name)
			if not participant then
				continue
			end

			participant:SetFreeKill(if reason == "nil" then nil else reason)
		end

		return `Set free kill reason of {getPlayersString(players)} to {reason}.`
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

module.setkarma = {
	Name = "setkarma",
	Description = "Sets the karma of players",
	Environment = "Server" :: "Server",
	Arguments = {"karma", "players"},
	Execute = function(executor: Player, round: Round, args: Args)
		local ServerScriptService = game:GetService("ServerScriptService")
		local KarmaManager = require(ServerScriptService.Player.KarmaManager)

		local players = processPlayerArgument(executor, args[2])
		if not players then
			return `Player {args[2]} not found.`
		end

		local karma = processNumberArgument(args[1])
		if not karma then
			return "Missing argument 1 karma."
		end

		for _, player in players do
			KarmaManager.SetKarma(player, karma)
			
			local participant = round:GetParticipant(player.Name)
			if not participant then
				continue
			end

			participant:SetKarma(karma)
		end

		return `Set karma of {getPlayersString(players)} to {karma}.`
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
			round:Finish(round:GetRoleFromRoleName(roleName))
			if round.Finish == disabledEndRound then
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

module.skipphase = {
	Name = "skipphase",
	Description = "Skips the current round phase",
	Environment = "Server" :: "Server",
	Arguments = {},
	Execute = function(_, round: Round): string
		local currentPhase: Types.Phase = round:GetPhase()
		if currentPhase == "Intermission" then
			return "Cannot skip intermission phase."
		end

		round.ElapsedPhaseTime = math.huge
		RunService.Heartbeat:Wait()
		RunService.Heartbeat:Wait()

		return `Skipped {currentPhase} phase to {round:GetPhase()}.`
	end
}

module.pause = {
	Name = "pause",
	Description = "Pauses or unpauses the round",
	Environment = "Server" :: "Server",
	Arguments = {},
	Execute = function(_, round: Types.Round)
		if round:GetPhase() == "Intermission" or round:GetPhase() == "Waiting" then
			return "Cannot pause during intermission or waiting phase."
		end
	
		round:Pause(not round:IsPaused())
		return if round:IsPaused() then "Round paused." else "Round unpaused."
	end
}

module.togglevictory = {
	Name = "togglevictory",
	Description = "Enables or disables victory",
	Environment = "Server" :: "Server",
	Arguments = {},
	Execute = toggleVictory
}

module.respawn = {
	Name = "respawn",
	Description = "Respawns the specified players",
	Environment = "Server" :: "Server",
	Arguments = {"players"},
	Execute = function(executor: Player, round: Types.Round, args: Args): string
		local players = processPlayerArgument(executor, args[1])
		if not players then
			return `Player {args[1]} not found.`
		end

		for _, player in players do
			local participant = round:GetParticipant(player.Name)
			if not participant then
				continue
			end

			round:RemoveParticipant(participant, true)
			round:AddPlayer(player, participant:GetKarma())
		end

		return "Respawned " .. getPlayersString(players) .. "."
	end
}

module.restart = {
	Name = "restart",
	Description = "Restarts the server",
	Environment = "Server" :: "Server",
	Arguments = {},
	Execute = function()
		local ServerScriptService = game:GetService("ServerScriptService")

		local RestartServer = require(ServerScriptService.Util.RestartServer)

		RestartServer(5)
		return "Server restarting..."
	end
}

module.forcegamemode = {
	Name = "forcegamemode",
	Description = "Forces the next round to use the specified gamemode",
	Environment = "Server" :: "Server",
	Arguments = {"gamemode name"},
	Execute = function(_, round: Round, args: Args): string
		local gamemodeName = processStringArgument(args[1])

		local ServerScriptService = game:GetService("ServerScriptService")
		local RoundHandler = (require)(ServerScriptService.RoundHandler)
		local result = RoundHandler.TrySetForcedGamemode(gamemodeName)

		return if result then `Set forced gamemode to {gamemodeName}.` else `Gamemode {gamemodeName} not found.`
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
		round:LoadMap(Map.fromModuleScript(map))

		return `Map changed to {mapName}.`
	end
}

module.listitems = {
	Name = "listitems",
	Description = "Lists all items",
	Environment = "Client" :: "Client",
	Arguments = {},
	Execute = function(): string
		local ret = ""
		for _, v in Items do
			ret ..= (if ret == "" then "" else "\n") .. v.Name
		end
		return ret
	end
}

module.spawninteractable = {
	Name = "spawninteractable",
	Description = "Spawns an interactable",
	Environment = "Server" :: "Server",
	Arguments = {"interactable", "spawn at players"},
	Execute = function(executor: Player, round: Round, args: Args): string
		local interactableName = processStringArgument(args[1])
		if not interactableName then
			return "Missing argument 1 interactable name."
		end

		local definition = round:GetInteractableDefinition(interactableName)
		if not definition then
			return `Interactable {interactableName} not found.`
		end

		local players = processPlayerArgument(executor, args[2])
		if not players then
			return `Player {args[2]} not found.`
		end

		for _, player in players do
			local participant = round:GetParticipant(player.Name)
			if not participant then
				continue
			end

			local char = participant:GetCharacter()
			if not char then
				continue
			end

			GetPrimaryPart(round:AddInteractable(definition).Object).CFrame = char:GetPivot()
		end

		return `Spawned {interactableName} at {getPlayersString(players)}.`
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