local fs = require("@lune/fs")
local net = require("@lune/net")
local serde = require("@lune/serde")
local roblox = require("@lune/roblox")
local process = require("@lune/process")
local BuildLib = require("./Lib/BuildLib")
local Env = require("./Lib/Env")

local BASE_URL = "https://apis.roblox.com/universes/v1/{universeId}/places/{placeId}/versions?versionType=Published"

local NAME = "Traitor.rbxl"

local STANDARD_UNIVERSE_ID = 1031123722

local MAIN_PLACE_ID = 2848381272
local TEST_PLACE_ID = 70750259318059

local LABS_PLACE_ID = 118757439615813
local LABS_UNIVERSE_ID = 8817594273

local place = process.args[1]

local placeId =
	if process.args[1] == "main" then
		MAIN_PLACE_ID
	elseif process.args[1] == "test" then
		TEST_PLACE_ID
	elseif process.args[1] == "labs" then
		LABS_PLACE_ID
	else
		error(`Invalid place: {place}. Expected "main", "test", or "labs".`)

local shouldPublish = process.args[2] == "publish"

local universeId = if placeId == LABS_PLACE_ID then LABS_UNIVERSE_ID else STANDARD_UNIVERSE_ID
local API_KEY = Env.APIKEY or error("Missing APIKEY in .env")

local PROJECT_FILE_PATH = "default.project.json"

local game = BuildLib(NAME, PROJECT_FILE_PATH)

local serviceProperties: {[string]: {[string]: any}} = {
	Lighting = {
		LightingStyle = (roblox :: any).Enum.LightingStyle.Soft, -- no type def exists for Enum, but it does exist
		PrioritizeLightingQuality = true,
	},
	Players = {
		BanningEnabled = placeId ~= LABS_PLACE_ID,
	},
	AssetService = {
		AllowInsertFreeAssets = placeId == LABS_PLACE_ID,
	},
}

for serviceName, properties in serviceProperties do
	local service = game:GetService(serviceName)
	for property, value in properties do
		service[property] = value
	end
end

local result = roblox.serializePlace(game)

fs.writeFile(NAME, result)

print(`Built {NAME} for {place} place.`)

if not shouldPublish then
	return
end

local response = net.request({
	url = BASE_URL:gsub("{universeId}", tostring(universeId)):gsub("{placeId}", tostring(placeId)),
	method = "POST",
	headers = {
		["x-api-key"] = API_KEY,
		["Content-Type"] = "application/octet-stream",
	},
	body = result,
})

assert(response.ok, `Failed to upload {NAME}: {response.body}`)
print(`Uploaded {NAME} with version: {serde.decode("json", response.body).versionNumber} to {place} place.`)