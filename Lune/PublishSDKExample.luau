local process = require("@lune/process")
local fs = require("@lune/fs")
local CloudTask = require("./Lib/CloudTask")

local EXAMPLE_MAPS = {"TestMap", "Facility"}
local EXAMPLE_GAMEMODES = {"ThoseYouTrust", "Framed", "Elimination"}

local GAMEMODES_PATH = "Source/Shared/GameDefinition/Gamemodes"
local MAPS_PATH = "Assets/Maps"

local ASSET_IDS = {
	["TestMap"] = 125557102994928,
	["Facility"] = 122192823669641,
	["ThoseYouTrust"] = 117084689582342,
	["Framed"] = 85240118809989,
	["Elimination"] = 73629714476044,
}

local function GetAssetPath(assetName: string, kind: "map" | "gamemode"): string
	if kind == "map" then
		assert(table.find(EXAMPLE_MAPS, assetName), `Map {assetName} is not valid for publishing.`)
		local mapPath = MAPS_PATH .. "/" .. assetName .. ".rbxm"
		assert(fs.isFile(mapPath), "Map file not found.")
		return mapPath
	end

	assert(table.find(EXAMPLE_GAMEMODES, assetName), `Gamemode {assetName} is not valid for publishing.`)
	local gamemodePath = GAMEMODES_PATH .. "/" .. assetName

	if fs.isDir(gamemodePath) then
		return gamemodePath
	elseif fs.isFile(gamemodePath .. ".luau") then
		return gamemodePath .. ".luau"
	end

	error("Gamemode file not found.")
end

local ASSET_PROJECT = [[{"name":"Publish Asset","tree":{"$className":"DataModel","ReplicatedStorage":{"[NAME]":{"$path":"[PATH]"}}}}]]

local function BuildPlace(assetName: string, assetPath: string): string
	local project = ASSET_PROJECT
		:gsub("%[NAME%]", assetName)
		:gsub("%[PATH%]", assetPath)

	local projectPath = "Asset.project.json"
	fs.writeFile(projectPath, project)

	local executionResult = process.exec("rojo", {"build", "--output", assetName .. ".rbxl", projectPath})

	fs.removeFile(projectPath)

	assert(executionResult.ok, executionResult.stderr)

	local result = fs.readFile(assetName .. ".rbxl")

	fs.removeFile(assetName .. ".rbxl")

	return result
end

local function publish(name: string, kind: "map" | "gamemode"): ()


	local assetId = ASSET_IDS[name]

	local placeData = BuildPlace(name, GetAssetPath(name, kind))
	local scriptContents = fs.readFile("Lune/Tasks/PublishAsset.luau")
		:gsub("0%d%d%d%d%d%d%d%d%d", tostring(assetId))
		:gsub("Enum%.AssetType%.Plugin", "Enum.AssetType.Model")


	CloudTask(placeData, scriptContents)
end

local kind = process.args[1]
assert(kind == "map" or kind == "gamemode" or kind == "all", "Invalid kind. Expected usage: PublishSDKExample map|gamemode|all mapName|gamemodeName")

if kind == "all" then
	for _, map in EXAMPLE_MAPS do
		print("Publishing map: " .. map)
		publish(map, "map")
	end
	for _, gamemode in EXAMPLE_GAMEMODES do
		print("Publishing gamemode: " .. gamemode)
		publish(gamemode, "gamemode")
	end
	return
end

local name = process.args[2]
assert(name, "Invalid name. Expected usage: PublishSDKExample map|gamemode mapName|gamemodeName")

publish(name, kind)