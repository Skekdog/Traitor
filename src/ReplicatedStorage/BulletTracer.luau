local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local function BulletTracer(projectile: BasePart, projectileSpeed: number, start: Vector3, target: Vector3): ()
	if RunService:IsServer() then
		return ReplicatedStorage.ServerClient.BulletTracer:FireAllClients(projectile, projectileSpeed, start, target)
	end

	projectile = projectile:Clone()
	projectile.CFrame = CFrame.new(start, target)
	projectile.Parent = workspace.Projectiles

	TweenService:Create(projectile, TweenInfo.new((start - target).Magnitude / projectileSpeed), {
		Position = target
	}):Play()
end

return BulletTracer