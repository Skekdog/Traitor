local process = require("@lune/process")
local fs = require("@lune/fs")
local PublishAsset = require("./Lib/PublishAsset")

local EXAMPLE_MAPS = {"TestMap", "Facility"}
local EXAMPLE_GAMEMODES = {"Traitor", "Framed", "Elimination", "PropHunt"}

local GAMEMODES_PATH = "Source/Shared/GameDefinition/Gamemodes"
local ITEMS_PATH = "Source/Shared/GameDefinition/Items"
local MAPS_PATH = "Assets/Maps"
local ASSETS_PATH = "Assets/Shared"
local INTERACTABLES_PATH = "Source/Shared/GameDefinition/Interactables"

local ASSET_IDS = {
	["TestMap"] = "109123324659232",
	["Facility"] = "126472909699829",
	["Traitor"] = "119447016204491",
	["Framed"] = "139092719483295",
	["Elimination"] = "81237358985439",
	["Items"] = "81535955487145",
	["Assets"] = "104086335415869",
	["PropHunt"] = "108921425683278",
	["Interactables"] = "114739037638623",
}

local function GetAssetPath(assetName: string, kind: "map" | "gamemode" | "items" | "assets" | "interactables"): string
	if kind == "map" then
		assert(table.find(EXAMPLE_MAPS, assetName), `Map {assetName} is not valid for publishing.`)
		local mapPath = MAPS_PATH .. "/" .. assetName .. ".rbxm"

		assert(fs.isFile(mapPath), "Map file not found.")

		return mapPath
	elseif kind == "gamemode" then
		assert(table.find(EXAMPLE_GAMEMODES, assetName), `Gamemode {assetName} is not valid for publishing.`)
		local gamemodePath = GAMEMODES_PATH .. "/" .. assetName

		if fs.isDir(gamemodePath) then
			return gamemodePath
		elseif fs.isFile(gamemodePath .. ".luau") then
			return gamemodePath .. ".luau"
		end

		error("Gamemode file not found.")
	elseif kind == "items" then
		return ITEMS_PATH
	elseif kind == "assets" then
		return ASSETS_PATH
	elseif kind == "interactables" then
		return INTERACTABLES_PATH
	end

	error("Invalid asset kind")
end

local function publish(assetName: string, kind: "map" | "gamemode" | "items" | "assets" | "interactables"): ()
	PublishAsset(ASSET_IDS[assetName], assetName, GetAssetPath(assetName, kind))
end

local kind = process.args[1]
assert(kind == "map" or kind == "gamemode" or kind == "items" or kind == "assets" or kind == "all", "Invalid kind. Expected usage: PublishSDKExample map|gamemode|items|all mapName|gamemodeName")

if kind == "all" then
	for _, map in EXAMPLE_MAPS do
		print("Publishing map: " .. map)
		publish(map, "map")
	end

	for _, gamemode in EXAMPLE_GAMEMODES do
		print("Publishing gamemode: " .. gamemode)
		publish(gamemode, "gamemode")
	end

	publish("Items", "items")
	publish("Interactables", "interactables")

	return
end

local name =
	if kind == "items" then "Items"
	elseif kind == "assets" then "Assets"
	else process.args[2]

assert(name, "Invalid name. Expected usage: PublishSDKExample map|gamemode|items|assets|interactables|all mapName|gamemodeName|all")

if name == "all" then
	if kind == "gamemode" then
		for _, gamemode in EXAMPLE_GAMEMODES do
			print("Publishing gamemode: " .. gamemode)
			publish(gamemode, kind)
		end
	elseif kind == "map" then
		for _, map in EXAMPLE_MAPS do
			print("Publishing map: " .. map)
			publish(map, kind)
		end
	else
		error("Invalid kind. Expected usage: PublishSDKExample map|gamemode|items|assets|all mapName|gamemodeName|all")
	end

	return
end

publish(name, kind)