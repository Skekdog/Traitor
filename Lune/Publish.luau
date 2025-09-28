local fs = require("@lune/fs")
local net = require("@lune/net")
local serde = require("@lune/serde")
local process = require("@lune/process")

local baseUrl = "https://apis.roblox.com/universes/v1/{universeId}/places/{placeId}/versions?versionType=Published"

assert(fs.isFile(".env"), "Missing .env file")
local env = serde.decode("toml", fs.readFile(".env"))

local NAME = "TT3"

local STANDARD_UNIVERSE_ID = 1031123722

local MAIN_PLACE_ID = 2848381272
local TEST_PLACE_ID = 70750259318059

local LABS_PLACE_ID = 118757439615813
local LABS_UNIVERSE_ID = 8817594273

local place = process.args[1]
assert(place == "main" or place == "test" or place == "labs", `Invalid place: {place}. Expected "main", "test", or "labs".`)

local placeId =
	if process.args[1] == "main" then
		MAIN_PLACE_ID
	elseif process.args[1] == "test" then
		TEST_PLACE_ID
	elseif process.args[1] == "labs" then
		LABS_PLACE_ID
	else
		error("what")

local UNIVERSE = if placeId == LABS_PLACE_ID then LABS_UNIVERSE_ID else STANDARD_UNIVERSE_ID
local API_KEY = env.APIKEY or error("Missing APIKEY in .env")

local PROJECT_FILE_PATH = "default.project.json"

local outputName = NAME .. ".rbxl"
local executionResult = process.exec("rojo", {"build", "--output", outputName, PROJECT_FILE_PATH})
assert(executionResult.ok, executionResult.stderr)

local outputFile = fs.readFile(outputName)

local response = net.request({
	url = baseUrl:gsub("{universeId}", tostring(UNIVERSE)):gsub("{placeId}", tostring(placeId)),
	method = "POST",
	headers = {
		["x-api-key"] = API_KEY,
		["Content-Type"] = "application/octet-stream",
	},
	body = outputFile,
})

assert(response.ok, `Failed to upload {outputName}: {response.body}`)
print(`Uploaded {outputName} with version: {serde.decode("json", response.body).versionNumber} to {place} place.`)