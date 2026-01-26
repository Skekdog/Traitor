local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Types = require(ReplicatedStorage.API.Types)
local ForEachPart = require(ReplicatedStorage.Shared.RoundRule.Common.ForEachPart)
local GetPrimaryPart = require(ReplicatedStorage.Shared.RoundRule.Common.GetPrimaryPart)

local IS_SERVER = RunService:IsServer()

local function BulletTracer(projectile: Types.MapObject, projectileSpeed: number, start: Vector3, target: Vector3, except: Player?, tempHide: boolean?): ()
	if IS_SERVER then
		for _, player in Players:GetPlayers() do
			if player ~= except then
				ReplicatedStorage.Remotes.ServerClient.BulletTracer:FireClient(player, projectile, projectileSpeed, start, target)
			end
		end
		return
	end

	projectile = projectile:Clone()

	if tempHide then
		ForEachPart(projectile, function(part)
			part.Transparency = 1
		end)

		task.delay(0.25, ForEachPart, projectile, function(part: BasePart)
			part.Transparency = 1
		end)
	end

	local part = GetPrimaryPart(projectile)
	part.CFrame = CFrame.new(start, target)
	part.Parent = workspace.Projectiles

	local tweenInfo = TweenInfo.new((start - target).Magnitude / projectileSpeed, Enum.EasingStyle.Linear)
	local tween = TweenService:Create(projectile, tweenInfo, {
		Position = target
	})

	tween.Completed:Once(function()
		projectile:Destroy()
	end)

	tween:Play()
end

if not IS_SERVER then
	ReplicatedStorage.Remotes.ServerClient.BulletTracer.OnClientEvent:Connect(BulletTracer)
end

return BulletTracer