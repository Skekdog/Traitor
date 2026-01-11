local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Types = require(ReplicatedStorage.API.Types)
local GetPrimaryPart = require(ReplicatedStorage.Shared.RoundRule.Common.GetPrimaryPart)

local IS_SERVER = RunService:IsServer()

local function BulletTracer(projectile: Types.MapObject, projectileSpeed: number, start: Vector3, target: Vector3, except: Player?): ()
	if IS_SERVER then
		for _, player in Players:GetPlayers() do
			if player ~= except then
				ReplicatedStorage.Remotes.ServerClient.BulletTracer:FireClient(player, projectile, projectileSpeed, start, target)
			end
		end
		return
	end

	projectile = projectile:Clone()

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