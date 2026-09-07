local AssetService = game:GetService("AssetService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local CheckAssetPermission = require(script.Parent.CheckAssetPermission)
local RoundHandler = require(script.Parent.Parent.RoundHandler)
local Map = require(ReplicatedStorage.Shared.RoundRule.Map)
local IsLabs = require(ReplicatedStorage.Shared.Places.IsLabs)
local Types = require(ReplicatedStorage.Shared.RoundRule.Types)

local module = {}

function module.LoadMap(assetId: number): Types.MapStructure
	if not IsLabs then
		error("Custom maps are only available in Labs.")
	end

	CheckAssetPermission(assetId)

	local mapScript = AssetService:LoadAssetAsync(assetId):FindFirstChildWhichIsA("Instance")
	if not mapScript then
		error("Asset is not a valid map")
	end

	mapScript.Sandboxed = false

	local existingMap = ServerStorage.Maps:FindFirstChild(mapScript.Name)
	if existingMap then
		existingMap:Destroy()
	end

	mapScript.Parent = ServerStorage.Maps

	local structure = Map.ValidateStructure(mapScript)
	RoundHandler.Round():LoadMap(structure)

	return structure
end

return table.freeze(module)