local fs = require("@lune/fs")
local process = require("@lune/process")
local CloudTask = require("./CloudTask")

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

local function PublishAsset(assetId: number, name: string, path: string): ()
	local placeData = BuildPlace(name, path)
	local scriptContents = fs.readFile("Lune/Tasks/PublishAsset.luau")
		:gsub("0%d%d%d%d%d%d%d%d%d", tostring(assetId))
		:gsub("Enum%.AssetType%.Plugin", "Enum.AssetType.Model")

	CloudTask(placeData, scriptContents)
end

return PublishAsset