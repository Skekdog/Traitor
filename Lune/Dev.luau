local DevSuite = require("@devsuite/DevSuite")
local PublishSDKAsset = require("@devsuite/PublishSDKAsset")
local SDKAssets = require("@devsuite/SDKAssets")
local UpdateCollisionGroups = require("@devsuite/UpdateCollisionGroups")
local Build = require("@devsuite/Build")
local fs = require("@lune/fs")
local datetime = require("@lune/datetime")
local process = require("@lune/process")

local ASCII_ART = [[
|-----------------------------------------------------------------------|
|                                                                       |
|  _______   _____               _____   _______    ____    _____    _  |
| |__   __| |  __ \      /\     |_   _| |__   __|  / __ \  |  __ \  | | |
|    | |    | |__) |    /  \      | |      | |    | |  | | | |__) | | | |
|    | |    |  _  /    / /\ \     | |      | |    | |  | | |  _  /  | | |
|    | |    | | \ \   / ____ \   _| |_     | |    | |__| | | | \ \  |_| |
|    |_|    |_|  \_\ /_/    \_\ |_____|    |_|     \____/  | |  \_| (_) |
|                                                                       |
|-----------------------------------------------------------------------|
]]

print()
print(ASCII_ART)
print("Wilkommen to the Traitor! Dev Suite.")
print()

local PLACE_PATH = "Traitor.rbxl"
local PLACE_FILE_STALE = 3600

local options: DevSuite.Options = {}

local sdkAssetsOptions: DevSuite.Options = {}

local function populateSDKAssets(optionsTable: DevSuite.Options, assetsTable: PublishSDKAsset.AssetsTable): ()
	optionsTable["! All"] = function(): ()
		PublishSDKAsset(assetsTable, "! All")
	end

	for name, id in assetsTable do
		if typeof(id) == "string" then
			optionsTable[name] = function(): ()
				PublishSDKAsset(assetsTable, name)
			end
		elseif typeof(id) == "table" then
			local newOptionsTable = {}
			optionsTable[name] = newOptionsTable
			populateSDKAssets(newOptionsTable, id)
		end
	end
end

populateSDKAssets(sdkAssetsOptions, SDKAssets)

options["Publish SDK Asset"] = sdkAssetsOptions

options["Update Collision Groups"] = function(): ()
	local meta = fs.metadata(PLACE_PATH)

	if not meta.exists then
		print("Missing place file:", PLACE_PATH)
		return
	end

	local modifiedAt: datetime.DateTime = meta.modifiedAt
	local timeNow = datetime.now()

	if (timeNow.unixTimestamp - modifiedAt.unixTimestamp) > PLACE_FILE_STALE then
		print(`Supplied {PLACE_PATH} is old (over {PLACE_FILE_STALE} seconds), consider generating a new one`)
	end

	UpdateCollisionGroups(PLACE_PATH)
end

local currentRojoProccess: process.ChildProcess?
options["Start Developing"] = function(): ()
	if currentRojoProccess then
		currentRojoProccess:kill()
		currentRojoProccess = nil
	end

	Build.Build("Labs")

	local startCommand = if process.os == "linux" then "xdg-open" else "start"

	process.exec(startCommand, {"Traitor.rbxl"}, {shell = true})
	currentRojoProccess = process.create("rojo", {"serve", "serve.project.json"})
end

local publishPlaceOptions: DevSuite.Options = {}

for name: Build.PlaceName in Build.PLACE_IDS do
	publishPlaceOptions[name] = function(): ()
		Build.Build(name, true)
	end
end

publishPlaceOptions["! All"] = function(): ()
	for name: Build.PlaceName in Build.PLACE_IDS do
		Build.Build(name, true)
	end
end

options["Publish Game"] = publishPlaceOptions

while DevSuite(options, {}) do
	continue
end