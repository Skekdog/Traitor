local fs = require("@lune/fs")
local PublishSDKAsset = require("./PublishSDKAsset")
local GenerateAPITypeStubs = require("./GenerateAPITypeStubs")

local GAMEMODES_PATH = "Source/Shared/GameDefinition/Gamemodes"
local ITEMS_PATH = "Source/Shared/GameDefinition/Items"
local MAPS_PATH = "Assets/Maps"
local ASSETS_PATH = "Assets/Shared"
local INTERACTABLES_PATH = "Source/Shared/GameDefinition/Interactables"

local assets: PublishSDKAsset.AssetsTable = {
	Map = {
		TestMap = "109123324659232",
		Facility = "126472909699829",

		GetPath = function(name: string): string
			local mapPath = MAPS_PATH .. "/" .. name .. ".rbxm"
			assert(fs.isFile(mapPath), "Map file not found")

			return mapPath
		end,
	},

	Gamemode = {
		Traitor = "119447016204491",
		Framed = "139092719483295",
		Elimination = "81237358985439",
		PropHunt = "108921425683278",

		GetPath = function(name): string
			local gamemodePath = GAMEMODES_PATH .. "/" .. name

			if fs.isDir(gamemodePath) then
				return gamemodePath
			elseif fs.isFile(gamemodePath .. ".luau") then
				return gamemodePath .. ".luau"
			end

			error("Gamemode file not found")
		end
	},

	Items = "81535955487145",
	Assets = "104086335415869",
	Interactables = "114739037638623",

	API = "117390899198330",

	GetPath = function(name): string
		if name == "Items" then
			return ITEMS_PATH
		elseif name == "Assets" then
			return ASSETS_PATH
		elseif name == "Interactables" then
			return INTERACTABLES_PATH
		elseif name == "API" then
			local path = GenerateAPITypeStubs.CreateFile()
			return path
		end

		error("Invalid asset")
	end,

	Cleanup = function(name): ()
		if name == "API" then
			GenerateAPITypeStubs.RemoveFile()
		end
	end
}

return table.freeze(assets)