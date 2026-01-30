local AssetService = game:GetService("AssetService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RoundHandler = require(script.Parent.Parent.RoundHandler)
local IsLabs = require(ReplicatedStorage.Shared.Places.IsLabs)

local module = {}

function module.LoadBoss(assetId: number): ()
	if not IsLabs then
		error("Custom bosses are only available in Labs.")
	end

	local bossScript = AssetService:LoadAssetAsync(assetId):FindFirstChildWhichIsA("Instance")
	if not bossScript then
		error("Asset is not a valid boss")
	end

	bossScript.Sandboxed = false

	local round = RoundHandler.Round()

	local bosses: Instance = round:GetMap().Structure:FindFirstChild("Bosses") or Instance.new("Configuration")
	if not bosses.Parent then
		bosses.Name = "Bosses"
		bosses.Parent = round:GetMap().Structure
	end

	local existingBoss = bosses:FindFirstChild(bossScript.Name)
	if existingBoss then
		existingBoss:Destroy()
	end

	bossScript.Parent = bosses
	RoundHandler.Round():LoadBoss((require)(bossScript))
end

return module