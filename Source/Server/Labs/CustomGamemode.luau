local AssetService = game:GetService("AssetService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CheckAssetPermission = require(script.Parent.CheckAssetPermission)
local IsLabs = require(ReplicatedStorage.Shared.Places.IsLabs)
local GamemodeValidation = require(ReplicatedStorage.Shared.RoundRule.GamemodeValidation)
local RoundHandler = require(script.Parent.Parent.RoundHandler)

local module = {}

function module.LoadGamemode(assetId: number): ()
	if not IsLabs then
		error("Custom gamemodes are only available in Labs.")
	end

	CheckAssetPermission(assetId)

	local gamemodeScript = AssetService:LoadAssetAsync(assetId):FindFirstChildWhichIsA("Instance")
	assert(gamemodeScript, "No asset was uploaded.")

	local existingGamemode = ReplicatedStorage.Shared.GameDefinition.Gamemodes:FindFirstChild(gamemodeScript.Name)
	if existingGamemode then
		existingGamemode.Parent = nil
	end

	gamemodeScript.Sandboxed = false
	gamemodeScript.Parent = ReplicatedStorage.Shared.GameDefinition.Gamemodes

	local success, result = pcall(GamemodeValidation.ValidateGamemodeScript, gamemodeScript)
	if not success then
		if existingGamemode then
			existingGamemode.Parent = ReplicatedStorage.Shared.GameDefinition.Gamemodes
		end
		gamemodeScript:Destroy()
		error(result)
	end

	if existingGamemode then
		existingGamemode:Destroy()
	end

	RoundHandler.UpdateLoadedGamemodes()
	RoundHandler.Round():LoadGamemode(result)
end

return table.freeze(module)