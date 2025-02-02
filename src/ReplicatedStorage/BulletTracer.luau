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

	local tweenInfo = TweenInfo.new((start - target).Magnitude / projectileSpeed, Enum.EasingStyle.Linear)
	local tween = TweenService:Create(projectile, tweenInfo, {
		Position = target
	})

	tween.Completed:Once(function()
		projectile:Destroy()
	end)
	
	tween:Play()
end

return BulletTracer