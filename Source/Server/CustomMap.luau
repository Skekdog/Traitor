local AssetService = game:GetService("AssetService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local RoundHandler = require(script.Parent.RoundHandler)
local Map = require(ReplicatedStorage.Shared.RoundRule.Map)

local module = {}

function module.LoadMap(assetId: number): ()
	local mapScript = AssetService:LoadAssetAsync(assetId):FindFirstChildWhichIsA("ModuleScript")
	if not mapScript then
		error("Asset is not a valid map script")
	end

	mapScript.Sandboxed = true
	mapScript.Capabilities = SecurityCapabilities.new(
		Enum.SecurityCapability.RunServerScript,
		Enum.SecurityCapability.RunClientScript,
		Enum.SecurityCapability.UI,
		Enum.SecurityCapability.Basic,
		Enum.SecurityCapability.CreateInstances,
		Enum.SecurityCapability.Animation,
		Enum.SecurityCapability.Audio,
		Enum.SecurityCapability.Avatar,
		Enum.SecurityCapability.Players,
		Enum.SecurityCapability.Physics,
		Enum.SecurityCapability.CSG,
		Enum.SecurityCapability.Environment,
		Enum.SecurityCapability.Network,
		Enum.SecurityCapability.Chat,
		Enum.SecurityCapability.Input
	)

	local existingMap = ServerStorage.Maps:FindFirstChild(mapScript.Name)
	if existingMap then
		existingMap:Destroy()
	end

	mapScript.Parent = ServerStorage.Maps
	RoundHandler.Round():LoadMap(Map.fromMapScript(Map.ValidateMapScript(mapScript)))
end

return module