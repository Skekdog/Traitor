local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local function BulletTracer(bulletName: string, projectileSpeed: number, start: Vector3, target: Vector3): ()
	if RunService:IsServer() then
		return ReplicatedStorage.ServerClient.BulletTracer:FireAllClients(bulletName, projectileSpeed, start, target)
	end
	
	local bullet = ReplicatedStorage.Projectiles:FindFirstChild(bulletName)
	assert(bullet and bullet:IsA("BasePart"), "Bullet not found")

	local bulletClone = bullet:Clone()
	bulletClone.CFrame = CFrame.new(start, target)
	bulletClone.Parent = workspace.Projectiles

	TweenService:Create(bulletClone, TweenInfo.new((start - target).Magnitude / projectileSpeed), {
		Position = target
	})
end

return BulletTracer