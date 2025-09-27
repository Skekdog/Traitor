local AssetService = game:GetService("AssetService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RoundHandler = require(script.Parent.Parent.RoundHandler)
local IsLabs = require(ReplicatedStorage.Shared.Util.IsLabs)

local module = {}

function module.LoadGamemode(assetId: number): ()
	if not IsLabs then
		error("Custom gamemodes are only available in Labs.")
	end

	local gamemodeScript = AssetService:LoadAssetAsync(assetId):FindFirstChildWhichIsA("ModuleScript")
	if not gamemodeScript then
		error("Asset is not a valid gamemode.")
	end

	gamemodeScript.Sandboxed = false

	local existingGamemode = ReplicatedStorage.Shared.GameDefinition.Gamemodes:FindFirstChild(gamemodeScript.Name)
	if existingGamemode then
		existingGamemode:Destroy()
	end

	gamemodeScript.Parent = ReplicatedStorage.Shared.GameDefinition.Gamemodes
	RoundHandler.UpdateLoadedGamemodes()
	RoundHandler.TrySetForcedGamemode(gamemodeScript.Name)
end

return module