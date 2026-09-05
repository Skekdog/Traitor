local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlaceIDs = require(ReplicatedStorage.Shared.Places.PlaceIDs)
local Types = require(ReplicatedStorage.Shared.RoundRule.Types)

local Arguments = {}

const WHITESPACE_SUBSTITUTE = "([^-])(%-)([^-])"
const SUBSTITUTE_SUBSTITUTE = "([^-])(%-%-)([^-])"

Arguments.Variadic = "..."
Arguments.PlayerSelectors = {"@a", "@o", "@s", "@r"}

function Arguments.String(str: string?): string?
	return if str then str:gsub(WHITESPACE_SUBSTITUTE, "%1 %3"):gsub(SUBSTITUTE_SUBSTITUTE, "%1-%3") else nil
end

function Arguments.Number(str: string?): number?
	return if str then tonumber(str) else nil
end

function Arguments.Item(gamemode: Types.GamemodeDefinition, map: Types.Map, str: string?): Types.ItemComponents?
	if not str then
		return nil
	end

	local lowercasedItems: {[string]: Types.ItemComponents} = {}

	-- NOTE: Ordering here matters! Map-specific items override gamemode items of the same name!
	for name, components in gamemode.AvailableItems do
		lowercasedItems[name:lower()] = components
	end

	for name, components in map.ItemDefinitions do
		lowercasedItems[name:lower()] = components
	end

	return lowercasedItems[str:lower()]
end

local function getLowercasedPlayers(): {[string]: Player}
	local players: {[string]: Player} = {}

	for _, player in Players:GetPlayers() do
		players[player.Name:lower()] = player
	end

	return players
end

local function getPartiallyMatchingPlayers(players: {[string]: Player}, input: string): {Player}
	local matches: {Player} = {}

	local loweredInput = input:lower()

	for name, player in players do
		if name:find("^" .. loweredInput) then
			table.insert(matches, player)
		end
	end

	return matches
end

function Arguments.Players(executor: Player, str: string?): {Player}?
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

	local players = getLowercasedPlayers()

	local player = players[str:lower()]
	if player then
		return {player}
	end

	local partialMatches = getPartiallyMatchingPlayers(players, str)
	if #partialMatches == 0 then
		return nil
	end

	return partialMatches
end

function Arguments.ExactPlayer(str: string?): Player?
	const player = if str then Players:FindFirstChild(str) else nil
	return if player and player:IsA("Player") then player else nil
end

const lowerPlaceIds: {[string]: number?} = {}
for name, id in PlaceIDs :: {[string]: number} do
	lowerPlaceIds[name:lower()] = id
end

function Arguments.Place(str: string?): number?
	return if str then lowerPlaceIds[str:lower()] else nil
end

function Arguments.Boss(map: Types.Map, str: string?): Types.BossDefinition?
	if not str then
		return nil
	end

	const lowerBosses: {[string]: Types.BossDefinition?} = {}
	for name, definition in map.Bosses do
		lowerBosses[name:lower()] = definition
	end

	return lowerBosses[str:lower()]
end

function Arguments.Gamemode(str: string?): ModuleScript?
	if not str then
		return nil
	end

	local module = ReplicatedStorage.Shared.GameDefinition.Gamemodes:FindFirstChild(str)
	return if module and module:IsA("ModuleScript") then module else nil
end

function Arguments.Map(str: string?): Instance?
	return nil
end

function Arguments.Role(gamemode: Types.GamemodeDefinition, str: string?): Types.RoleDefinition?
	if not str then
		return nil
	end

	const loweredRoles: {[string]: Types.RoleDefinition?} = {}
	for name, definition in gamemode.Roles do
		loweredRoles[name:lower()] = definition
	end

	return loweredRoles[str:lower()]
end

return table.freeze(Arguments)