local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local TeleportService = game:GetService("TeleportService")
local ServerScriptService = game:GetService("ServerScriptService")
local StandardGame = require(ReplicatedStorage.API.StandardGame)
local Types = require(ReplicatedStorage.API.Types)
local Map = require(ReplicatedStorage.Shared.RoundRule.Map)
local RelaxedPermissions = require(script.Parent.RelaxedPermissions)
local PlaceIDs = require(ReplicatedStorage.Shared.Places.PlaceIDs)

export type BaseCommand = {
	Name: string,
	Description: string,
	HasRelaxedPermissions: boolean?,
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

local function getPartiallyMatchingPlayers(players: {Player}, input: string): {Player}
	local matches: {Player} = {}

	for _, player in players do
		if player.Name:find("^" .. input) then
			table.insert(matches, player)
		end
	end

	return matches
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
	elseif str == "@o" then
		local players = Players:GetPlayers()

		local index = table.find(players, executor)
		if index then
			table.remove(players, index)
		end

		return players
	end

	local player = Players:FindFirstChild(str)
	if player and player:IsA("Player") then
		return {player}
	end

	local partialMatches = getPartiallyMatchingPlayers(Players:GetPlayers(), str)
	if #partialMatches == 0 then
		return nil
	end

	return partialMatches
end

local function getPlayersString(players: {Player}): string
	local ret = ""

	for _, player in players do
		ret ..= `{player.Name}{if player ~= players[#players] then ", " else ""}`
	end

	if ret == "" then
		ret = "nobody"
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
	HasRelaxedPermissions = true,
	Arguments = {},
	Execute = function()
		local ret = "Players can be specified using name, partial name, @s (self), @a (all players), @r (random), or @o (others).\nCommands:\n"

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

module.xray = {
	Name = "xray",
	Description = "Turns all static map parts semi-transparent.",
	HasRelaxedPermissions = true,
	Environment = "Client" :: "Client",
	Arguments = {},

	Execute = function(): string
		local LocalRoundInfo = require(ReplicatedStorage.Shared.LocalState.LocalRoundInfo)
		local map = LocalRoundInfo.Map()

		if not map then
			return "No map loaded."
		end

		local enabled = not (map.Structure.Static:GetAttribute("XRayEnabled") :: boolean?)
		map.Structure.Static:SetAttribute("XRayEnabled", enabled)

		for _, instance in map.Structure.Static:GetDescendants() do
			if not instance:IsA("BasePart") and not instance:IsA("Texture") then
				continue
			end

			if instance:IsA("BasePart") and instance.CollisionGroup == "Bounds" then
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
	HasRelaxedPermissions = true,
	Environment = "Client" :: "Client",
	Arguments = {},
	Execute = function(): string
		local LocalRoundInfo = require(ReplicatedStorage.Shared.LocalState.LocalRoundInfo)
		local map = LocalRoundInfo.Map()

		if not map then
			return "No map loaded."
		end

		local enabled = not (map.Structure.Static:GetAttribute("ShowBounds") :: boolean?)
		map.Structure.Static:SetAttribute("ShowBounds", enabled)

		for _, instance in map.Structure.Static:GetDescendants() do
			if not instance:IsA("BasePart") or instance.CollisionGroup ~= "Bounds" then
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
	HasRelaxedPermissions = true,
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
	HasRelaxedPermissions = true,
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
	HasRelaxedPermissions = true,
	Environment = "Client" :: "Client",
	Arguments = {},
	Execute = function(player: Player, args: Args)
		local Camera = require(ReplicatedStorage.API.Camera)
		if Camera.IsFirstPerson() then
			Camera.EnterThirdPerson()
		else
			Camera.EnterFirstPerson()
		end

		return `Third person {if Camera.IsFirstPerson() then "disabled" else "enabled"}.`
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
	HasRelaxedPermissions = true,
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

		local affectedPlayers: {Player} = {}
		for _, target in targets do
			local char = target.Character
			if char then
				local root = char.PrimaryPart
				if root then
					root.AssemblyLinearVelocity = Vector3.zero
				end
				char:PivotTo(toChar:GetPivot())
				table.insert(affectedPlayers, target)
			end
		end

		return `Teleported {getPlayersString(affectedPlayers)} to {to[1].Name}.`
	end
}

module.setrole = {
	Name = "setrole",
	Description = "Sets the roles of players",
	HasRelaxedPermissions = true,
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

		local success, result = pcall(round.GetRoleFromRoleName, round, roleName)
		if not success then
			return `Role {roleName} not found.`
		end

		local affectedPlayers: {Player} = {}
		for _, player in players do
			local participant = round:GetParticipant(player.Name)
			if not participant then
				continue
			end

			participant:SetRole(result.Definition)

			table.insert(affectedPlayers, player)
		end

		return `Set roles of {getPlayersString(affectedPlayers)} to {roleName}.`
	end
}

module.setfreekill = {
	Name = "setfreekill",
	Description = "Sets free kill reason for the specified players",
	HasRelaxedPermissions = true,
	Environment = "Server" :: "Server",
	Arguments = {"reason / nil", "players"},
	Execute = function(executor: Player, round: Round, args: Args): string
		local players = processPlayerArgument(executor, args[2])
		if not players then
			return `Player {args[2]} not found.`
		end

		local reason = processStringArgument(args[1])

		local affectedPlayers: {Player} = {}
		for _, player in players do
			local participant = round:GetParticipant(player.Name)
			if not participant then
				continue
			end

			participant:SetFreeKill(if reason == "nil" then nil else reason)

			table.insert(affectedPlayers, player)
		end

		return `Set free kill reason of {getPlayersString(affectedPlayers)} to {reason}.`
	end
}

module.kill = {
	Name = "kill",
	Description = "Kills the specified players",
	HasRelaxedPermissions = true,
	Environment = "Server" :: "Server",
	Arguments = {"player name"},
	Execute = function(executor: Player, round: Round, args: Args)
		local players = processPlayerArgument(executor, args[1])
		if not players then
			return `Player {args[1]} not found.`
		end

		local affectedPlayers: {Player} = {}
		for _, player in players do
			local participant = round:GetParticipant(player.Name)
			if not participant then
				continue
			end

			participant:TryTakeDamage({
				Amount = math.huge,
				Source = "Other"
			})

			table.insert(affectedPlayers, player)
		end

		return `Killed {getPlayersString(affectedPlayers)}.`
	end
}

module.setkarma = {
	Name = "setkarma",
	Description = "Sets the karma of players",
	Environment = "Server" :: "Server",
	Arguments = {"karma", "players"},
	Execute = function(executor: Player, round: Round, args: Args)
		local KarmaManager = require(ServerScriptService.Player.KarmaManager)

		local players = processPlayerArgument(executor, args[2])
		if not players then
			return `Player {args[2]} not found.`
		end

		local karma = processNumberArgument(args[1])
		if not karma then
			return "Missing argument 1 karma."
		end

		local affectedPlayers: {Player} = {}
		for _, player in players do
			KarmaManager.SetKarma(player, karma)

			local participant = round:GetParticipant(player.Name)
			if not participant then
				continue
			end

			participant:SetKarma(karma)

			table.insert(affectedPlayers, player)
		end

		return `Set karma of {getPlayersString(affectedPlayers)} to {karma}.`
	end
}

module.endround = {
	Name = "endround",
	Description = "Ends the current round with a victory for the specified role",
	HasRelaxedPermissions = true,
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
	HasRelaxedPermissions = true,
	Environment = "Server" :: "Server",
	Arguments = {},
	Execute = function(_, round: Round): string
		local currentPhase: Types.Phase = round:GetPhase()

		round:Pause(false)
		round.ElapsedPhaseTime = math.huge

		RunService.Heartbeat:Wait()
		RunService.Heartbeat:Wait()

		return `Skipped {currentPhase} phase to {round:GetPhase()}.`
	end
}

module.pause = {
	Name = "pause",
	Description = "Pauses or unpauses the round",
	HasRelaxedPermissions = true,
	Environment = "Server" :: "Server",
	Arguments = {},
	Execute = function(_, round: Types.Round)
		if round:GetPhase() == "Waiting" then
			return "Cannot pause during waiting phase."
		end

		round:Pause(not round:IsPaused())
		return if round:IsPaused() then "Round paused." else "Round unpaused."
	end
}

module.togglevictory = {
	Name = "togglevictory",
	Description = "Enables or disables victory",
	HasRelaxedPermissions = true,
	Environment = "Server" :: "Server",
	Arguments = {},
	Execute = toggleVictory
}

module.respawn = {
	Name = "respawn",
	Description = "Respawns the specified players",
	HasRelaxedPermissions = true,
	Environment = "Server" :: "Server",
	Arguments = {"players"},
	Execute = function(executor: Player, round: Types.Round, args: Args): string
		local KarmaManager = require(ServerScriptService.Player.KarmaManager)
		local players = processPlayerArgument(executor, args[1])
		if not players then
			return `Player {args[1]} not found.`
		end

		for _, player in players do
			local participant = round:GetParticipant(player.Name)
			if participant then
				participant:SpawnCharacter()
			else
				round:AddPlayer(player, KarmaManager.GetKarma(player))
			end
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
		local RestartServer = require(ServerScriptService.Util.RestartServer)

		RestartServer(5)
		return "Server restarting..."
	end
}

module.gamemode = {
	Name = "gamemode",
	Description = "Changes the gamemode",
	HasRelaxedPermissions = true,
	Environment = "Server" :: "Server",
	Arguments = {"gamemode name"},
	Execute = function(_, round: Round, args: Args): string
		local CustomGamemode = require(ServerScriptService.Labs.CustomGamemode)
		local gamemodeName = processStringArgument(args[1])

		if not gamemodeName then
			return "Missing argument 1 gamemode name / asset id."
		end

		local assetId = processNumberArgument(gamemodeName)
		if assetId then
			CustomGamemode.LoadGamemode(assetId)
			return `Gamemode changed to asset ID {assetId}.`
		end

		local gamemodeModule = ReplicatedStorage.Shared.GameDefinition.Gamemodes:FindFirstChild(gamemodeName)
		if not gamemodeModule then
			return `Gamemode {gamemodeName} not found.`
		end

		local success, result = pcall(function()
			round:LoadGamemode((require)(gamemodeModule))
		end)

		if not success then
			return result
		end

		return `Gamemode changed to {gamemodeName}.`
	end
}

module.boss = {
	Name = "boss",
	Description = "Loads a boss from the current map or from an asset id",
	Environment = "Server" :: "Server",
	HasRelaxedPermissions = true,
	Arguments = {"boss name / asset id"},
	Execute = function(_, round: Round, args: Args): string
		local bossName = processStringArgument(args[1])
		if not bossName then
			return "Missing argument 1 boss name / asset id."
		end

		local assetId = processNumberArgument(bossName)
		if assetId then
			return "not implemented"
		end

		local boss = round:GetMap().Bosses[bossName]
		if not boss then
			return `Boss {bossName} not found.`
		end

		round:LoadBoss(boss)

		return `Loaded boss {bossName}.`
	end
}

module.map = {
	Name = "map",
	Description = "Changes the map",
	Environment = "Server" :: "Server",
	HasRelaxedPermissions = true,
	Arguments = {"map name / asset id"},
	Execute = function(_, round: Round, args: Args)
		local CustomMap = require(ServerScriptService.Labs.CustomMap)
		local mapName = processStringArgument(args[1])
		if not mapName then
			return "Missing argument 1 map name / asset id."
		end

		local assetId = processNumberArgument(mapName)
		if assetId then
			CustomMap.LoadMap(assetId)
			return `Map changed to asset ID {assetId}.`
		end

		local map = ServerStorage.Maps:FindFirstChild(mapName)
		if not map then
			return `Map {mapName} not found.`
		end
		round:LoadMap(Map.ValidateStructure(map:Clone()))

		return `Map changed to {mapName}.`
	end
}

module.listitems = {
	Name = "listitems",
	Description = "Lists all items",
	Environment = "Client" :: "Client",
	HasRelaxedPermissions = true,
	Arguments = {},
	Execute = function(): string
		local ret = ""
		for _, v in StandardGame.GetItems() do
			ret ..= (if ret == "" then "" else "\n") .. v.Name
		end
		return ret
	end
}

module.spawninteractable = {
	Name = "spawninteractable",
	Description = "Spawns an interactable",
	HasRelaxedPermissions = true,
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

		if not definition.Model then
			return `Interactable {interactableName} does not have a model.`
		end

		local players = processPlayerArgument(executor, args[2])
		if not players then
			return `Player {args[2]} not found.`
		end

		local affectedPlayers: {Player} = {}
		for _, player in players do
			local participant = round:GetParticipant(player.Name)
			if not participant then
				continue
			end

			local char = participant:GetCharacter()
			if not char then
				continue
			end

			local model = definition.Model:Clone()
			model:AddTag("Interactable")
			model:AddTag("Prop")
			model:RemoveTag("Item")

			local interactable = round:LoadProp(model)
			interactable.Model:PivotTo(char:GetPivot())

			;(interactable.Model :: Instance).Parent = round:GetMap().Structure.Dynamic

			table.insert(affectedPlayers, player)
		end

		return `Spawned {interactableName} at {getPlayersString(affectedPlayers)}.`
	end
}

module.spawnitem = {
	Name = "spawnitem",
	Description = "Spawns an item at players",
	HasRelaxedPermissions = true,
	Environment = "Server" :: "Server",
	Arguments = {"item name", "players"},
	Execute = function(executor: Player, round: Round, args: Args): string
		local players = processPlayerArgument(executor, args[2])
		if not players then
			return `Player {args[2]} not found.`
		end

		local itemName = processStringArgument(args[1])
		if not itemName then
			return "Missing argument 1 item name."
		end

		local item = round:GetItemDefinition(itemName)
		if not item then
			return `Item {itemName} not found.`
		end

		if not item.Model then
			return `Item has no model and cannot be spawned, consider using giveitem instead.`
		end

		local affectedPlayers: {Player} = {}
		for _, player in players do
			local participant = round:GetParticipant(player.Name)
			if not participant then
				continue
			end

			local char = participant:GetCharacter()
			if not char then
				continue
			end

			local model = item.Model:Clone()
			model:PivotTo(char:GetPivot())
			model:AddTag("Item")
			model:AddTag("Prop");
			(model :: Instance).Parent = round:GetMap().Structure.Dynamic

			table.insert(affectedPlayers, player)
		end

		return `Spawned {itemName} at {getPlayersString(affectedPlayers)}.`
	end
}

module.giveitem = {
	Name = "giveitem",
	Description = "Gives an item to players",
	HasRelaxedPermissions = true,
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

		local item = round:GetItemDefinition(itemName)
		if not item then
			return `Item {itemName} not found.`
		end

		local affectedPlayers: {Player} = {}
		for _, player in players do
			local participant = round:GetParticipant(player.Name)
			if not participant or participant:GetItemOccupyingGroup(item.ItemGroup) then
				continue
			end

			participant:AddItem(round:LoadItem(item))
			table.insert(affectedPlayers, player)
		end

		return `Gave {itemName} to {getPlayersString(affectedPlayers)}.`
	end
}

module.removeitem = {
	Name = "removeitem",
	Description = "Removes an item from players.",
	HasRelaxedPermissions = true,
	Environment = "Server" :: "Server",
	Arguments = {"item name", "players"},
	Execute = function(executor: Player, round: Round, args: {string?}): string
		local players = processPlayerArgument(executor, args[2])
		if not players then
			return `Player {args[2]} not found.`
		end

		local itemName = processStringArgument(args[1])
		if not itemName then
			return "Missing argument 1 item name."
		end

		if not round:GetItemDefinition(itemName) then
			return `Item {itemName} not found.`
		end

		local affectedPlayers: {Player} = {}
		for _, player in players do
			local participant = round:GetParticipant(player.Name)
			if not participant then
				continue
			end

			local item: Types.Item?

			for _, found in participant:GetItems() do
				assert(found)
				if found.Name == itemName then
					item = found
					break
				end
			end

			if item then
				participant:RemoveItem(item, true)
				table.insert(affectedPlayers, player)
			end
		end

		return `Removed {itemName} from {getPlayersString(affectedPlayers)}.`
	end
}

module.givecredits = {
	Name = "givecredits",
	Description = "Gives credits to players",
	HasRelaxedPermissions = true,
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

		local affectedPlayers: {Player} = {}
		for _, player in players do
			local participant = round:GetParticipant(player.Name)
			if not participant then
				continue
			end

			participant:AddCredits(amount)

			table.insert(affectedPlayers, player)
		end

		return `Gave {amount} credits to {getPlayersString(affectedPlayers)}.`
	end
}

module.spawndummy = {
	Name = "spawndummy",
	Description = "Spawns a test dummy that can be damaged.",
	HasRelaxedPermissions = true,
	Environment = "Server" :: "Server",
	Arguments = {"at players"},
	Execute = function(executor: Player, round: Round, args: Args): string
		local players = processPlayerArgument(executor, args[1])
		if not players then
			return `Player {args[1]} not found.`
		end

		local affectedPlayers: {Player} = {}
		for _, player in players do
			if not player.Character then
				continue
			end

			local dummy = ReplicatedStorage.Shared.RoundRule.Assets.TestDummy:Clone()
			dummy:PivotTo(player.Character:GetPivot())

			dummy.Parent = round:GetMap().Structure.Dynamic :: any

			table.insert(affectedPlayers, player)
		end

		return `Spawned test dummy at {getPlayersString(affectedPlayers)}.`
	end
}

module.sethealth = {
	Name = "sethealth",
	Description = "Sets health of players to a specified value",
	HasRelaxedPermissions = true,
	Environment = "Server" :: "Server",
	Arguments = {"health", "players"},
	Execute = function(executor: Player, round: Round, args: Args): string
		local players = processPlayerArgument(executor, args[2])
		if not players then
			return `Player {args[2]} not found.`
		end

		local health = processNumberArgument(args[1])
		if not health then
			return "Invalid argument 1 health."
		end

		local affectedPlayers: {Player} = {}
		for _, player in players do
			local participant = round:GetParticipant(player.Name)
			if not participant then
				continue
			end

			local humanoid = participant:GetHumanoid()
			if humanoid then
				humanoid.MaxHealth = math.max(health, humanoid.MaxHealth)
				humanoid.Health = health
				table.insert(affectedPlayers, player)
			end
		end

		return `Set health to {health} for {getPlayersString(affectedPlayers)}.`
	end
}

module.relax = {
	Name = "relax",
	Description = "Temporarily grants relaxed command permissions to players.",
	Arguments = {"players"},
	Environment = "Server" :: "Server",
	HasRelaxedPermissions = true,
	Execute = function(executor: Player, round: Round, args: Args): string
		local players = processPlayerArgument(executor, args[1])
		if not players then
			return `Player {args[1]} not found.`
		end

		local affectedPlayers: {Player} = {}
		for _, player in players do
			if not RelaxedPermissions.HasRelaxedPermissions(player) then
				RelaxedPermissions.GivePermission(player)
				table.insert(affectedPlayers, player)
			end
		end

		return `Gave relaxed permissions to {getPlayersString(affectedPlayers)}.`
	end
}

module.seance = {
	Name = "seance",
	Description = "Makes chat from dead players visible to everyone.",
	Arguments = {},
	Environment = "Server" :: "Server",
	HasRelaxedPermissions = true,
	Execute = function(executor: Player, round: Round): string
		local FilterDead = require(ServerScriptService.Chat.FilterDead)
		local Message = require(ReplicatedStorage.API.Interface.Message)
		FilterDead.SetDisabled(not FilterDead.IsDisabled())

		local isEnabled = FilterDead.IsDisabled()
		local output = `Seance is now {if isEnabled then "enabled" else "disabled"}. Dead chat is {if isEnabled then "now" else "no longer"} visible to alive players.`
		Message.Chat(output, "All")

		return output
	end
}

module.ragdoll = {
	Name = "ragdoll",
	Description = "Forces a player to ragdoll indefinitely.",
	Arguments = {"players"},
	Environment = "Server" :: "Server",
	HasRelaxedPermissions = true,
	Execute = function(executor: Player, round: Round, args: Args): string
		local Ragdoll = require(ReplicatedStorage.Shared.RoundRule.Ragdoll)

		local players = processPlayerArgument(executor, args[1])
		if not players then
			return `Player {args[1]} not found.`
		end

		local affectedPlayers: {Player} = {}
		for _, player in players do
			local participant = round:GetParticipant(player.Name)
			if not participant then
				continue
			end

			local character = participant:GetCharacter()
			if not character then
				continue
			end

			Ragdoll.Ragdoll(participant, character)
			table.insert(affectedPlayers, player)
		end

		return `Ragdolled {getPlayersString(affectedPlayers)}.`
	end
}

module.unragdoll = {
	Name = "unragdoll",
	Description = "Forces a player to unragdoll.",
	Arguments = {"players"},
	Environment = "Server" :: "Server",
	HasRelaxedPermissions = true,
	Execute = function(executor: Player, round: Round, args: Args): string
		local Ragdoll = require(ReplicatedStorage.Shared.RoundRule.Ragdoll)

		local players = processPlayerArgument(executor, args[1])
		if not players then
			return `Player {args[1]} not found.`
		end

		local affectedPlayers: {Player} = {}
		for _, player in players do
			local participant = round:GetParticipant(player.Name)
			if not participant then
				continue
			end

			local character = participant:GetCharacter()
			if not character then
				continue
			end

			Ragdoll.Unragdoll(character)
			table.insert(affectedPlayers, player)
		end

		return `Unragdolled {getPlayersString(affectedPlayers)}.`
	end
}

return table.freeze(module)