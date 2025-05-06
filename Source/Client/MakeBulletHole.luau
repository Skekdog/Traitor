local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local CreateEmptyPart = require(ReplicatedStorage.RoundRule.Common.CreateEmptyPart)

local function tryFadeBulletHole(impactHole: BasePart, impactDecal: Decal, weld: WeldConstraint): ()
	if not impactHole:IsDescendantOf(workspace) then
		return
	end

	local tween = TweenService:Create(impactDecal, TweenInfo.new(5), {Transparency = 1})
	tween.Completed:Connect(function()
		if not impactHole:IsDescendantOf(workspace) then
			return
		end
		weld:Destroy()
		impactHole:Destroy()
	end)

	impactHole.Destroying:Once(function()
		if tween.PlaybackState == Enum.PlaybackState.Playing then
			tween:Cancel()
		end
	end)

	tween:Play()
end

local function createImpactHole(part: BasePart, relativeCFrame: CFrame, normal: Vector3): (BasePart, Decal, WeldConstraint)
	local position = part.CFrame:ToWorldSpace(relativeCFrame).Position
    local impactHole = CreateEmptyPart(CFrame.lookAt(position, position + normal))
    impactHole.Anchored = false
    impactHole.Size = Vector3.new(0.5, 0.5, 0.1)
	impactHole.CFrame *= CFrame.Angles(0, 0, math.rad(math.random(360)))
    
    local impactDecal = Instance.new("Decal")
    impactDecal.Texture = "rbxassetid://130624105"
    impactDecal.Parent = impactHole
    
    local weld = Instance.new("WeldConstraint")
    weld.Part0 = part
    weld.Part1 = impactHole
    weld.Parent = part
    
    impactHole.Parent = part

	return impactHole, impactDecal, weld
end

local function MakeBulletHole(part: BasePart, relativeCFrame: CFrame, normal: Vector3): ()
	local impactHole, impactDecal, weld = createImpactHole(part, relativeCFrame, normal)
	task.wait(5)
	tryFadeBulletHole(impactHole, impactDecal, weld)
end

ReplicatedStorage.ServerClient.MakeBulletHole.OnClientEvent:Connect(MakeBulletHole)

return MakeBulletHole