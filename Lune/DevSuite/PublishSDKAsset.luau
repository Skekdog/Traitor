local PublishAsset = require("@lib/PublishAsset")

export type AssetsTable = {
	[string]: string | AssetsTable,

	GetPath: (name: string) -> string,
	Cleanup: (name: string) -> ()?,
}

local function checkName(name: string): ()
	assert(name ~= "! All" and name ~= "GetPath" and name ~= "Cleanup", "Name must not be ! All, GetPath, or Cleanup")
end

local function publish(assetsTable: AssetsTable, assetName: string): ()
	checkName(assetName)

	local assetId = assetsTable[assetName]
	assert(typeof(assetId) == "string", "Invalid assets table for asset name: " .. assetName)

	PublishAsset(assetId, assetName, assetsTable.GetPath(assetName))

	if assetsTable.Cleanup then
		assetsTable.Cleanup(assetName)
	end
end

local function PublishSDKAsset(assetsTable: AssetsTable, assetName: string | "!All"): ()
	if assetName ~= "! All" then
		checkName(assetName)
		return publish(assetsTable, assetName)
	end

	for name, id in assetsTable do
		if typeof(id) ~= "string" then
			if typeof(id) == "function" then
				continue
			end

			PublishSDKAsset(id, "! All")

			continue
		end

		publish(assetsTable, assetName)
	end
end

return PublishSDKAsset