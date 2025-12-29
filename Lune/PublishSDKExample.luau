local process = require("@lune/process")
local fs = require("@lune/fs")
local PublishAsset = require("./Lib/PublishAsset")

local EXAMPLE_MAPS = {"TestMap", "Facility"}
local EXAMPLE_GAMEMODES = {"ThoseYouTrust", "Framed", "Elimination"}

local GAMEMODES_PATH = "Source/Shared/GameDefinition/Gamemodes"
local ITEMS_PATH = "Source/Shared/GameDefinition/Items"
local MAPS_PATH = "Assets/Maps"

local ASSET_IDS = {
	["TestMap"] = 125557102994928,
	["Facility"] = 122192823669641,
	["ThoseYouTrust"] = 117084689582342,
	["Framed"] = 85240118809989,
	["Elimination"] = 73629714476044,
	["Items"] = 71521398249549,
}

local function GetAssetPath(assetName: string, kind: "map" | "gamemode" | "items"): string
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
	end

	error("Invalid asset kind")
end

local function publish(assetName: string, kind: "map" | "gamemode" | "items"): ()
	PublishAsset(ASSET_IDS[assetName], assetName, GetAssetPath(assetName, kind))
end

local kind = process.args[1]
assert(kind == "map" or kind == "gamemode" or kind == "items" or kind == "all", "Invalid kind. Expected usage: PublishSDKExample map|gamemode|items|all mapName|gamemodeName")

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

	return
end

local name = if kind == "items" then "Items" else process.args[2]
assert(name, "Invalid name. Expected usage: PublishSDKExample map|gamemode mapName|gamemodeName")

publish(name, kind)