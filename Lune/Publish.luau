local fs = require("@lune/fs")
local net = require("@lune/net")
local serde = require("@lune/serde")
local process = require("@lune/process")

local baseUrl = "https://apis.roblox.com/universes/v1/{universeId}/places/{placeId}/versions?versionType=Published"

assert(fs.isFile(".env"), "Missing .env file")
local env = serde.decode("toml", fs.readFile(".env"))

local NAME = "Those You Trust"

local MAIN_PLACE_ID = 2848381272
local TEST_PLACE_ID = 70750259318059

local place = process.args[1]
assert(place == "main" or place == "test", `Invalid place: {place}. Expected "main" or "test".`)

local placeId = if process.args[1] == "main" then MAIN_PLACE_ID else TEST_PLACE_ID

local UNIVERSE = 1031123722
local API_KEY = env.APIKEY or error("Missing APIKEY in .env")

local PROJECT_FILE_PATH = "default.project.json"

local outputName = NAME .. ".rbxl"
local buildResult = process.exec("rojo", {"build", "--output", outputName, PROJECT_FILE_PATH})
assert(buildResult.ok, buildResult.stderr)

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