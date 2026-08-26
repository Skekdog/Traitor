local fs = require("@lune/fs")
local net = require("@lune/net")
local process = require("@lune/process")
local Env = require("@lib/Env")

local ASSET_PROJECT = [[
{
	"name": "[NAME]",
	"emitLegacyScripts": false,
	"tree": {
		"$path": "[PATH]"
	}
}
]]

local ASSET_PROJECT_PATH = "Asset.project.json"
local ASSET_OUTPUT_PATH = "Asset.rbxm"

local function BuildAsset(assetName: string, assetPath: string): string
	local project = ASSET_PROJECT
		:gsub("%[PATH%]", assetPath)
		:gsub("%[NAME%]", assetName)

	fs.writeFile(ASSET_PROJECT_PATH, project)

	local executionResult = process.exec("rojo", {"build", "--output", ASSET_OUTPUT_PATH, ASSET_PROJECT_PATH})
	assert(executionResult.ok, executionResult.stderr)

	local result = fs.readFile(ASSET_OUTPUT_PATH)

	fs.removeFile(ASSET_OUTPUT_PATH)
	fs.removeFile(ASSET_PROJECT_PATH)

	return result
end

local function PublishAsset(assetId: string, assetName: string, assetPath: string): ()
	local asset = BuildAsset(assetName, assetPath)

	local request = buffer.create(#asset + 8 + 1)
	buffer.writef64(request, 0, tonumber(assetId) or 0)
	buffer.copy(request, 8, buffer.fromstring(asset))

	local response = net.request({
		url = "https://traitor-uploader.gurkz.me/assets/",
		method = "PATCH",
		headers = {
			["Content-Type"] = "application/octet-stream",
			["Authorization"] = "Bearer " .. assert(Env.UPLOADER_KEY, "Please provide the uploader key"),
		},
		body = buffer.tostring(request)
	})

	if not response.ok then
		error(`Failed to upload {assetName} ({assetId}): {response.statusCode} {response.body}`)
	end
	print(`Uploaded asset {assetName} ({assetId})`)
end

return PublishAsset