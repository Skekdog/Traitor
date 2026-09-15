local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local ServerScriptService = game:GetService("ServerScriptService")
local TextService = game:GetService("TextService")
local Arguments = require(script.Parent.Arguments)
local StandardGame = require(ReplicatedStorage.API.StandardGame)
local Types = require(ReplicatedStorage.API.Types)
local Map = require(ReplicatedStorage.Shared.RoundRule.Map)
local RelaxedPermissions = require(script.Parent.RelaxedPermissions)
local IsLabs = require(ReplicatedStorage.Shared.Places.IsLabs)

type ArgumentType = Arguments.ArgumentType

-- Type solver fails if we type-cast to this type in command definitions, but for correctness we can use it in the type definition for a command.
type TypeList = {{ArgumentType?}?}

export type BaseCommand = {
	Name: string,
	Description: string,
	Category: string,
	HasRelaxedPermissions: boolean?,

	-- note: can't map string to argumenttype because arguments must be ordered
	Arguments: {string},
	Types: TypeList,
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

local Commands: {[string]: Command} = {}

Commands.help = {
	Name = "help",
	Category = "Other",
	Description = "Lists all commands.",
	Environment = "Client" :: "Client",
	HasRelaxedPermissions = true,

	Arguments = {},
	Types = {},

	Execute = function()
		local ret = "Players can be specified using name, partial name, @s (self), @a (all players), @r (random), or @o (others).\nCommands:"

		local categories: {[string]: {string}?} = {}
		for _, command in Commands do
			local args = if #command.Arguments == 0 then "" else " "
			for i, arg in command.Arguments do
				args ..= `<{arg}>{if i < #command.Arguments then " " else ""}`
			end

			local help = `{command.Name}{args}: {command.Description}`

			local categoryList = categories[command.Category]
			if not categoryList then
				categories[command.Category] = {help}
				continue
			end

			table.insert(categoryList, help)
		end

		-- Each item could be inserted in at the current index, instead of sorting afterwards.
		-- That's probably faster and would get you more marks in a computer science test, but I don't care
		local sortedCategories: {string} = {}
		for category, commands in categories do
			table.sort(assert(commands))
			table.insert(sortedCategories, category)
		end
		table.sort(sortedCategories)


		for _, category in sortedCategories do
			local helpMessages = assert(categories[category])
			table.insert(helpMessages, 1, "\n\n-- " .. category:upper() .. "\n")
			ret ..= table.concat(helpMessages, "\n")
		end

		return ret
	end
}

Commands.echo = {
	Name = "echo",
	Category = "Developer",
	Description = "Processes arguments and returns the result.",
	HasRelaxedPermissions = true,
	Environment = "Server" :: "Server",

	Arguments = {Arguments.Variadic},
	Types = {{"any"}} :: {{ArgumentType}},

	Execute = function(player: Player, round: Round, args: Args): string
		local processed: {string} = {}

		for _, arg in args do
			local output: string

			local players = Arguments.Players(player, arg)
			local item = Arguments.Item(round.Gamemode, round:GetMap(), Arguments.String(arg))

			if players then
				output = getPlayersString(players)
			elseif item then
				output = item.Name
			else
				output = tostring(Arguments.Number(arg) or Arguments.String(arg) or "ERR")
			end

			table.insert(processed, output)
		end

		return table.concat(processed, " | ")
	end
}

Commands.xray = {
	Name = "xray",
	Category = "Visuals",
	Description = "Turns all static map parts semi-transparent.",
	HasRelaxedPermissions = true,
	Environment = "Client" :: "Client",

	Arguments = {},
	Types = {},

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

Commands.showbounds = {
	Name = "showbounds",
	Category = "Visuals",
	Description = "Toggles showing of map bounds.",
	HasRelaxedPermissions = true,
	Environment = "Client" :: "Client",

	Arguments = {},
	Types = {},

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

Commands.noclip = {
	Name = "noclip",
	Category = "Player",
	Description = "Toggles noclip on/off.",
	HasRelaxedPermissions = true,
	Environment = "Client" :: "Client",

	Arguments = {},
	Types = {},

	Execute = function(player: Player, args: Args)
		local NoClip = require(script.Parent.NoClip)
		local enabled = NoClip.Enable()
		return `Noclip {if enabled then "enabled" else "disabled"}.`
	end
}

Commands.freecam = {
	Name = "freecam",
	Category = "Visuals",
	Description = "Toggles freecam on/off.",
	HasRelaxedPermissions = true,
	Environment = "Client" :: "Client",

	Arguments = {},
	Types = {},

	Execute = function(player: Player, args: Args)
		local Freecam = require(ReplicatedStorage.Shared.Camera.Freecam)
		local enabled = Freecam.ToggleFreecam()
		return `Freecam {if enabled then "enabled" else "disabled"}.`
	end
}

Commands.thirdperson = {
	Name = "thirdperson",
	Category = "Visuals",
	Description = "Toggles thirdperson on/off.",
	HasRelaxedPermissions = true,
	Environment = "Client" :: "Client",

	Arguments = {},
	Types = {},

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

Commands.teleportplace = {
	Name = "teleportplace",
	Category = "Other",
	Description = "Teleports specified players to the specified place.\nAvailable named places: Imperium, MainPlace, TestPlace",
	Environment = "Server" :: "Server",

	Arguments = {"place name / id", "players"},
	Types = {{"place", "number"}, {"players"}} :: {{ArgumentType}},

	Execute = function(executor: Player, round: Round, args: Args)
		local asId = Arguments.Number(args[1])
		local asName = Arguments.String(args[1])
		local place = if asId then asId else Arguments.Place(Arguments.String(asName))

		if not place then
			return "Place not found."
		end

		local players = Arguments.Players(executor, args[2])
		if not players then
			return `Player {args[2]} not found.`
		end

		TeleportService:TeleportAsync(place, players)
		return `Teleporting {getPlayersString(players)} to {place}.`
	end
}

Commands.teleport = {
	Name = "teleport",
	Category = "Character",
	Description = "Teleports players to another player.",
	HasRelaxedPermissions = true,
	Environment = "Server" :: "Server",

	Arguments = {"to", "targets"},
	Types = {{"players"}, {"players"}} :: {{ArgumentType}},

	Execute = function(executor: Player, round: Round, args: Args): string
		local to = Arguments.Players(executor, args[1])
		if not to then
			return `Player {args[1]} not found.`
		end

		local targets = Arguments.Players(executor, args[2])
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

Commands.role = {
	Name = "role",
	Category = "Player",
	Description = "Sets the roles of players.",
	HasRelaxedPermissions = true,
	Environment = "Server" :: "Server",

	Arguments = {"role name", "players"},
	Types = {{"role"}, {"players"}} :: {{ArgumentType}},

	Execute = function(executor: Player, round: Round, args: Args)
		local players = Arguments.Players(executor, args[2])
		if not players then
			return `Player {args[2]} not found.`
		end

		local name = Arguments.String(args[1])
		if not name then
			return "Missing argument 1 role."
		end

		local definition = Arguments.Role(round.Gamemode, name)
		if not definition then
			return `Role {name} not found.`
		end

		local role = round:GetRoleFromRoleName(definition.Name)

		local affectedPlayers: {Player} = {}
		for _, player in players do
			local participant = round:GetParticipant(player.Name)
			if not participant then
				continue
			end

			participant:SetRole(role.Definition)

			table.insert(affectedPlayers, player)
		end

		return `Set roles of {getPlayersString(affectedPlayers)} to {definition.Name}.`
	end
}

Commands.freekill = {
	Name = "freekill",
	Category = "Player",
	Description = "Sets free kill reason for the specified players.",
	HasRelaxedPermissions = true,
	Environment = "Server" :: "Server",

	Arguments = {"reason?", "players"},
	Types = {{"string", "optional"}, {"players"}} :: {{ArgumentType}},

	Execute = function(executor: Player, round: Round, args: Args): string
		local players = Arguments.Players(executor, args[2])
		if not players then
			return `Player {args[2]} not found.`
		end

		local reason = Arguments.String(args[1])
		if reason then
			local filterResult = TextService:FilterStringAsync(reason, executor.UserId)
			reason = filterResult:GetNonChatStringForBroadcastAsync()
		end

		local affectedPlayers: {Player} = {}
		for _, player in players do
			local participant = round:GetParticipant(player.Name)
			if not participant then
				continue
			end

			participant:SetFreeKill(reason)

			table.insert(affectedPlayers, player)
		end

		return `Set free kill reason of {getPlayersString(affectedPlayers)} to {reason}.`
	end
}

Commands.kill = {
	Name = "kill",
	Category = "Character",
	Description = "Kills the specified players.",
	HasRelaxedPermissions = true,
	Environment = "Server" :: "Server",

	Arguments = {"players"},
	Types = {{"players"}} :: {{ArgumentType}},

	Execute = function(executor: Player, round: Round, args: Args)
		local players = Arguments.Players(executor, args[1])
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

Commands.karma = {
	Name = "karma",
	Category = "Player",
	Description = "Sets the karma of players.",
	Environment = "Server" :: "Server",

	Arguments = {"karma", "players"},
	Types = {{"number"}, {"players"}} :: {{ArgumentType}},

	Execute = function(executor: Player, round: Round, args: Args)
		local KarmaManager = require(ServerScriptService.Player.KarmaManager)

		local players = Arguments.Players(executor, args[2])
		if not players then
			return `Player {args[2]} not found.`
		end

		local karma = Arguments.Number(args[1])
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

Commands.finishround = {
	Name = "finishround",
	Category = "Game",
	Description = "Finishes the current round with a victory for the specified role.",
	HasRelaxedPermissions = true,
	Environment = "Server" :: "Server",

	Arguments = {"role name"},
	Types = {{"role"}} :: {{ArgumentType}},

	Execute = function(_, round: Round, args: Args)
		local name = Arguments.String(args[1])
		if not name then
			return "Missing argument 1 role name."
		end

		local definition = Arguments.Role(round.Gamemode, name)
		if not definition then
			return `Role {name} not found.`
		end

		if not round:IsInProgress() then
			return "Round is not in progress."
		end

		local success, err = pcall(function()
			round:Finish(round:GetRoleFromRoleName(definition.Name))
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

Commands.skip = {
	Name = "skip",
	Category = "Game",
	Description = "Skips the current round phase.",
	HasRelaxedPermissions = true,
	Environment = "Server" :: "Server",

	Arguments = {},
	Types = {},

	Execute = function(_, round: Round): string
		local currentPhase: Types.Phase = round:GetPhase()

		round:Pause(false)
		round.ElapsedPhaseTime = math.huge

		RunService.Heartbeat:Wait()
		RunService.Heartbeat:Wait()

		return `Skipped {currentPhase} phase to {round:GetPhase()}.`
	end
}

Commands.pause = {
	Name = "pause",
	Category = "Game",
	Description = "Pauses or unpauses the round.",
	HasRelaxedPermissions = true,
	Environment = "Server" :: "Server",

	Arguments = {},
	Types = {},

	Execute = function(_, round: Types.Round)
		if round:GetPhase() == "Waiting" then
			return "Cannot pause during waiting phase."
		end

		round:Pause(not round:IsPaused())
		return if round:IsPaused() then "Round paused." else "Round unpaused."
	end
}

Commands.togglevictory = {
	Name = "togglevictory",
	Category = "Game",
	Description = "Enables or disables victory.",
	HasRelaxedPermissions = true,
	Environment = "Server" :: "Server",

	Arguments = {},
	Types = {},

	Execute = toggleVictory
}

Commands.respawn = {
	Name = "respawn",
	Category = "Character",
	Description = "Respawns the specified players.",
	HasRelaxedPermissions = true,
	Environment = "Server" :: "Server",

	Arguments = {"players"},
	Types = {{"players"}} :: {{ArgumentType}},

	Execute = function(executor: Player, round: Types.Round, args: Args): string
		local KarmaManager = require(ServerScriptService.Player.KarmaManager)
		local players = Arguments.Players(executor, args[1])
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

Commands.despawn = {
	Name = "despawn",
	Category = "Character",
	Description = "Despawns the specified players.",
	HasRelaxedPermissions = true,
	Environment = "Server" :: "Server",

	Arguments = {"players"},
	Types = {{"players"}} :: {{ArgumentType}},

	Execute = function(executor: Player, round: Types.Round, args: Args): string
		local players = Arguments.Players(executor, args[1])
		if not players then
			return `Player {args[1]} not found.`
		end

		local affectedPlayers: {Player} = {}
		for _, player in players do
			local participant = round:GetParticipant(player.Name)
			if participant and participant:GetCharacter() then
				round:RemoveParticipant(participant, false)
			end
			table.insert(affectedPlayers, player)
		end

		return `Despawned {getPlayersString(players)}.`
	end
}

Commands.restart = {
	Name = "restart",
	Category = "Other",
	Description = "Restarts the server.",
	Environment = "Server" :: "Server",

	Arguments = {},
	Types = {},

	Execute = function()
		local RestartServer = require(ServerScriptService.Util.RestartServer)

		if IsLabs then
			return "Server restarts are not currently possible in Labs. Try `kick @a` instead."
		end

		RestartServer(5)
		return "Server restarting..."
	end
}

Commands.kick = {
	Name = "kick",
	Category = "Other",
	Description = "Kicks players from the server.",
	Environment = "Server" :: "Server",
	HasRelaxedPermissions = true,

	Arguments = {"players"},
	Types = {{"players"}} :: {{ArgumentType}},

	Execute = function(executor: Player, _, args): string
		local players = Arguments.Players(executor, args[1])
		if not players then
			return "Invalid argument 1 players."
		end

		for _, player in players do
			player:Kick("Kicked by a moderator.")
		end

		return `Kicked {getPlayersString(players)}.`
	end
}

Commands.gamemode = {
	Name = "gamemode",
	Category = "Game",
	Description = "Changes the gamemode.",
	HasRelaxedPermissions = true,
	Environment = "Server" :: "Server",

	Arguments = {"gamemode name"},
	Types = {{"gamemode"}, {{kind = "literal", literal = "perm"}, "optional"}} :: {{ArgumentType}},

	Execute = function(_, round: Round, args: Args): string
		local CustomGamemode = require(ServerScriptService.Labs.CustomGamemode)
		local RoundHandler = require(ServerScriptService.RoundHandler)

		local gamemodeName = Arguments.String(args[1])

		if not gamemodeName then
			return "Missing argument 1 gamemode name / asset id."
		end

		local assetId = Arguments.Number(gamemodeName)
		if assetId then
			CustomGamemode.LoadGamemode(assetId)
			return `Gamemode changed to asset ID {assetId}.`
		end

		local gamemodeModule = Arguments.Gamemode(gamemodeName)
		if not gamemodeModule then
			return `Gamemode {gamemodeName} not found.`
		end

		local success, result = pcall(function()
			local gamemode = (require)(gamemodeModule)
			round:LoadGamemode(gamemode)
			return gamemode
		end)

		if not success then
			return result
		end

		local isPerm = (Arguments.String(args[2]) or ""):lower() == "perm"
		if isPerm then
			RoundHandler.SetForcedGamemode(result)
		else
			RoundHandler.SetForcedGamemode()
		end

		return `Gamemode changed to {gamemodeName}.`
	end
}

Commands.boss = {
	Name = "boss",
	Category = "Game",
	Description = "Loads a boss from the current map or from an asset id.",
	Environment = "Server" :: "Server",
	HasRelaxedPermissions = true,

	Arguments = {"boss name / asset id"},
	Types = {{"boss", "number"}} :: {{ArgumentType}},

	Execute = function(_, round: Round, args: Args): string
		local bossName = Arguments.String(args[1])
		if not bossName then
			return "Missing argument 1 boss name / asset id."
		end

		local assetId = Arguments.Number(bossName)
		if assetId then
			return "not implemented"
		end

		local boss = Arguments.Boss(round:GetMap(), bossName)
		if not boss then
			return `Boss {bossName} not found.`
		end

		round:LoadBoss(boss)

		return `Loaded boss {bossName}.`
	end
}

Commands.map = {
	Name = "map",
	Category = "Game",
	Description = "Changes the map.",
	Environment = "Server" :: "Server",
	HasRelaxedPermissions = true,

	Arguments = {"map name / asset id"},
	Types = {{"map", "number"}, {{kind = "literal", literal = "perm"}, "optional"}} :: {{ArgumentType}},

	Execute = function(_, round: Round, args: Args)
		local CustomMap = require(ServerScriptService.Labs.CustomMap)
		local RoundHandler = require(ServerScriptService.RoundHandler)

		local mapName = Arguments.String(args[1])
		if not mapName then
			return "Missing argument 1 map name / asset id."
		end

		local assetId = Arguments.Number(mapName)
		if assetId then
			RoundHandler.SetForcedMap(CustomMap.LoadMap(assetId))
			return `Map changed to asset ID {assetId}.`
		end

		local map = Arguments.Map(mapName)
		if not map then
			return `Map {mapName} not found.`
		end

		local structure = Map.ValidateStructure(map:Clone())
		round:LoadMap(structure)

		local isPerm = (Arguments.String(args[2]) or ""):lower() == "perm"
		if isPerm then
			RoundHandler.SetForcedMap(structure)
		else
			RoundHandler.SetForcedMap(nil)
		end

		return `Map changed to {mapName}.`
	end
}

Commands.gravity = {
	Name = "gravity",
	Category = "Game",
	Description = "Sets gravity to the specified value.",
	Environment = "Server" :: "Server",
	HasRelaxedPermissions = true,

	Arguments = {"value"},
	Types = {{"number"}} :: {{ArgumentType}},

	Execute = function(_, _, args): string
		local value = Arguments.Number(args[1])
		if not value then
			return "Invalid argument 1 gravity."
		end

		workspace.Gravity = value

		return `Set gravity to {value}.`
	end
}

Commands.listitems = {
	Name = "listitems",
	Category = "Item",
	Description = "Lists all items.",
	Environment = "Client" :: "Client",
	HasRelaxedPermissions = true,

	Arguments = {},
	Types = {},

	Execute = function(): string
		local ret = ""
		for _, v in StandardGame.GetItems() do
			ret ..= (if ret == "" then "" else "\n") .. v.Name
		end
		return ret
	end
}

Commands.give = {
	Name = "give",
	Category = "Item",
	Description = "Gives an item to players.",
	HasRelaxedPermissions = true,
	Environment = "Server" :: "Server",

	Arguments = {"item name", "players"},
	Types = {{"item"}, {"players"}} :: {{ArgumentType}},

	Execute = function(executor: Player, round: Round, args: {string?})
		local players = Arguments.Players(executor, args[2])
		if not players then
			return `Player {args[2]} not found.`
		end

		local itemName = Arguments.String(args[1])
		if not itemName then
			return "Missing argument 1 item name."
		end

		local item = Arguments.Item(round.Gamemode, round:GetMap(), itemName)
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

		return `Gave {item.Name} to {getPlayersString(affectedPlayers)}.`
	end
}

Commands.remove = {
	Name = "remove",
	Category = "Item",
	Description = "Removes an item from players.",
	HasRelaxedPermissions = true,
	Environment = "Server" :: "Server",

	Arguments = {"item name", "players"},
	Types = {{"item"}, {"players"}} :: {{ArgumentType}},

	Execute = function(executor: Player, round: Round, args: {string?}): string
		local players = Arguments.Players(executor, args[2])
		if not players then
			return `Player {args[2]} not found.`
		end

		local itemName = Arguments.String(args[1])
		if not itemName then
			return "Missing argument 1 item name."
		end

		local itemComponents = Arguments.Item(round.Gamemode, round:GetMap(), itemName)
		if not itemComponents then
			return `Item {itemName} not found.`
		end

		local loweredName = itemComponents.Name:lower()

		local affectedPlayers: {Player} = {}
		for _, player in players do
			local participant = round:GetParticipant(player.Name)
			if not participant then
				continue
			end

			local item: Types.Item?

			for _, found in participant:GetItems() do
				assert(found)
				if found.Name:lower() == loweredName then
					item = found
					break
				end
			end

			if item then
				participant:RemoveItem(item, true)
				table.insert(affectedPlayers, player)
			end
		end

		return `Removed {itemComponents.Name} from {getPlayersString(affectedPlayers)}.`
	end
}

Commands.credits = {
	Name = "credits",
	Category = "Player",
	Description = "Sets credit counts of players.",
	HasRelaxedPermissions = true,
	Environment = "Server" :: "Server",

	Arguments = {"amount", "players"},
	Types = {{"number"}, {"players"}} :: {{ArgumentType}},

	Execute = function(executor: Player, round: Round, args: Args)
		local players = Arguments.Players(executor, args[2])
		if not players then
			return `Player {args[2]} not found.`
		end

		local amount = Arguments.Number(args[1])
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

		return `Set credits of {getPlayersString(affectedPlayers)} to {amount}.`
	end
}

Commands.dummy = {
	Name = "dummy",
	Category = "Developer",
	Description = "Spawns a test dummy that can be damaged.",
	HasRelaxedPermissions = true,
	Environment = "Server" :: "Server",

	Arguments = {"at players"},
	Types = {{"players"}} :: {{ArgumentType}},

	Execute = function(executor: Player, round: Round, args: Args): string
		local players = Arguments.Players(executor, args[1])
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

Commands.health = {
	Name = "health",
	Category = "Character",
	Description = "Sets health of players to a specified value",
	HasRelaxedPermissions = true,
	Environment = "Server" :: "Server",

	Arguments = {"health", "players"},
	Types = {{"number"}, {"players"}} :: {{ArgumentType}},

	Execute = function(executor: Player, round: Round, args: Args): string
		local players = Arguments.Players(executor, args[2])
		if not players then
			return `Player {args[2]} not found.`
		end

		local health = Arguments.Number(args[1])
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

Commands.relax = {
	Name = "relax",
	Category = "Other",
	Description = "Temporarily grants relaxed command permissions to players.",

	Arguments = {"players"},
	Types = {{"players"}} :: {{ArgumentType}},

	Environment = "Server" :: "Server",
	HasRelaxedPermissions = true,
	Execute = function(executor: Player, round: Round, args: Args): string
		local players = Arguments.Players(executor, args[1])
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

Commands.seance = {
	Name = "seance",
	Category = "Game",
	Description = "Makes chat from dead players visible to everyone.",

	Arguments = {},
	Types = {},

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

Commands.ragdoll = {
	Name = "ragdoll",
	Category = "Character",
	Description = "Forces a player to (un)ragdoll indefinitely.",

	Arguments = {"players"},
	Types = {{"players"}} :: {{ArgumentType}},

	Environment = "Server" :: "Server",
	HasRelaxedPermissions = true,
	Execute = function(executor: Player, round: Round, args: Args): string
		local Ragdoll = require(ReplicatedStorage.Shared.RoundRule.Ragdoll)

		local players = Arguments.Players(executor, args[1])
		if not players then
			return `Player {args[1]} not found.`
		end

		local ragdolledPlayers: {Player} = {}
		local unragdolledPlayers: {Player} = {}

		for _, player in players do
			local participant = round:GetParticipant(player.Name)
			if not participant then
				continue
			end

			local character = participant:GetCharacter()
			if not character then
				continue
			end

			if character:HasTag("Ragdoll") then
				Ragdoll.Unragdoll(character)
				table.insert(unragdolledPlayers, player)
			else
				Ragdoll.Ragdoll(participant, character)
				table.insert(ragdolledPlayers, player)
			end
		end

		return `Ragdolled {getPlayersString(ragdolledPlayers)}, unragdolled {getPlayersString(unragdolledPlayers)}`
	end
}


Commands.ban = {
	Name = "ban",
	Category = "Moderation",
	Description = "Bans a player.",

	Arguments = {"exact username / id", "duration / perm", "display reason", "private reason"},
	Types = {{"exact_player", "number"}, {"number", {kind = "literal", literal = "perm"}}, {"string"}, {"string"}} :: {{ArgumentType}},

	Environment = "Server" :: "Server",

	-- Note: this command requires exact names / ids to avoid banning the wrong people
	Execute = function(executor: Player, _, args: Args): string
		local Ban = require(ServerScriptService.Moderation.Ban)

		if IsLabs then
			return "Banning is not possible in Labs."
		end

		local nameOrId = args[1]
		if not nameOrId then
			return `A player username or id must be provided.`
		end

		local durationArg = args[2]
		if not durationArg then
			return `A duration must be provided.`
		end

		local displayReason = Arguments.String(args[3])
		if not displayReason then
			return `A display reason must be provided.`
		end

		local privateReason = Arguments.String(args[4])
		if not privateReason then
			return `A private reason must be provided.`
		end

		local duration = 0

		local durationAsNumber = tonumber(durationArg)
		if durationAsNumber then
			duration = durationAsNumber
		elseif durationArg == "perm" then
			duration = -1
		else
			return `Invalid duration. Either provide a number or "perm".`
		end

		local player = Players:FindFirstChild(nameOrId)
		if player and player:IsA("Player") then
			Ban.Temp(player, duration, displayReason, privateReason)
			return "Banned " .. player.Name
		end

		local asId = Arguments.Number(nameOrId)
		if asId then
			player = Players:GetPlayerByUserId(asId)
		end

		if player and player:IsA("Player") then
			Ban.Temp(player, duration, displayReason, privateReason)
			return "Banned " .. player.Name
		end

		return "Player not found. They must be in the server to be banned via the console."
	end
}

Commands.unban = {
	Name = "unban",
	Category = "Moderation",
	Description = "Unbans a player.",

	Arguments = {"exact id"},
	Types = {{"number"}} :: {{ArgumentType}},

	Environment = "Server" :: "Server",

	Execute = function(_, _, args: Args): string
		local Ban = require(ServerScriptService.Moderation.Ban)

		if IsLabs then
			return "Unbanning is not possible in Labs."
		end

		local id = Arguments.Number(args[1])
		if not id then
			return `Invalid user id.`
		end

		Ban.Unban(id)

		return "Unbanned " .. id
	end
}

Commands.data = {
	Name = "data",
	Category = "Item",
	Description = "Edits an item's components within a player's inventory.",

	Arguments = {"item name", "component", "value", "players"},
	Types = {{"item"}, {"string"}, {"number", "string"}, {"players"}} :: {{ArgumentType}},

	Environment = "Server" :: "Server",

	Execute = function(executor: Player, round: Round, args: Args): string
		local Replication = require(ReplicatedStorage.Shared.RoundRule.Replication)

		local players = Arguments.Players(executor, args[4])
		if not players then
			return `Player {args[4]} not found.`
		end

		local itemName = Arguments.String(args[1])
		if not itemName then
			return `Missing argument 1 item name.`
		end

		local itemBase = Arguments.Item(round.Gamemode, round:GetMap(), itemName)
		if not itemBase then
			return `Item {itemName} not found.`
		end

		local componentName = Arguments.String(args[2])
		if not componentName then
			return `Missing argument 2 component name.`
		end

		local value = Arguments.Number(args[3]) or Arguments.String(args[3])
		if not value then
			return `Missing argument 3 value.`
		end

		local baseValue = itemBase[componentName]
		if typeof(baseValue) ~= typeof(value) and baseValue ~= nil then
			return `Invalid value, expected a {typeof(baseValue)} but got a {typeof(value)}`
		end

		local affectedPlayers: {Player} = {}

		for _, player in players do
			local participant = round:GetParticipant(player.Name)
			if not participant then
				continue
			end

			local item: Types.Item?
			for _, foundItem in participant:GetItems() do
				assert(foundItem)
				if foundItem.Base == itemBase then
					item = foundItem
					break
				end
			end

			if not item then
				continue
			end

			item[componentName] = value
			table.insert(affectedPlayers, player)

			Replication.UpdateInventory(player, "Update", item)
		end

		return `Modified "{itemBase.Name}".{componentName} to {value} for {getPlayersString(affectedPlayers)}.`
	end
}

return table.freeze(Commands)