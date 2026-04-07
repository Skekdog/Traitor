local fs = require("@lune/fs")
local net = require("@lune/net")
local serde = require("@lune/serde")
local roblox = require("@lune/roblox")
local BuildLib = require("@lib/BuildLib")
local Env = require("@lib/Env")

local BASE_URL = "https://apis.roblox.com/universes/v1/{universeId}/places/{placeId}/versions?versionType=Published"

local NAME = "Traitor.rbxl"

local Build = {}

export type PlaceName = "Main" | "Test" | "Labs"

local PLACE_IDS: {[PlaceName]: string} = {
	Main = "2848381272",
	Test = "70750259318059",
	Labs = "118757439615813",
}

Build.PLACE_IDS = PLACE_IDS

local UNIVERSE_IDS = {
	Main = "1031123722",
	Labs = "8817594273",
}

function Build.Build(place: PlaceName, shouldPublish: boolean?): ()
	local API_KEY = Env.APIKEY or error("Missing APIKEY in .env")
	local placeId = Build.PLACE_IDS[place]

	local universeId = if place == "Labs" then UNIVERSE_IDS.Labs else UNIVERSE_IDS.Main

	local PROJECT_FILE_PATH = "build.project.json"

	local game = BuildLib(NAME, PROJECT_FILE_PATH)

	local serviceProperties: {[string]: {[string]: any}} = {
		Lighting = {
			LightingStyle = (roblox :: any).Enum.LightingStyle.Soft, -- no type def exists for Enum, but it does exist
			PrioritizeLightingQuality = true,
		},
		Players = {
			BanningEnabled = place ~= "Labs",
		},
		AssetService = {
			AllowInsertFreeAssets = place == "Labs",
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
		url = BASE_URL:gsub("{universeId}", tostring(universeId)):gsub("{placeId}", placeId),
		method = "POST",
		headers = {
			["x-api-key"] = API_KEY,
			["Content-Type"] = "application/octet-stream",
		},
		body = result,
	})

	assert(response.ok, `Failed to upload {NAME}: {response.body}`)
	print(`Uploaded {NAME} with version: {serde.decode("json", response.body).versionNumber} to {place} place.`)
end

return table.freeze(Build)