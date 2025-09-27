local AssetService = game:GetService("AssetService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local RoundHandler = require(script.Parent.Parent.RoundHandler)
local Map = require(ReplicatedStorage.Shared.RoundRule.Map)
local IsLabs = require(ReplicatedStorage.Shared.Util.IsLabs)

local module = {}

function module.LoadMap(assetId: number): ()
	if not IsLabs then
		error("Custom maps are only available in Labs.")
	end

	local mapScript = AssetService:LoadAssetAsync(assetId):FindFirstChildWhichIsA("ModuleScript")
	if not mapScript then
		error("Asset is not a valid map script")
	end

	mapScript.Sandboxed = false

	local existingMap = ServerStorage.Maps:FindFirstChild(mapScript.Name)
	if existingMap then
		existingMap:Destroy()
	end

	mapScript.Parent = ServerStorage.Maps
	RoundHandler.Round():LoadMap(Map.fromMapScript(Map.ValidateMapScript(mapScript)))
end

return module