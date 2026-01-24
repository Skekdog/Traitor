local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GetMapObject = require(ReplicatedStorage.API.GetMapObject)
local GetMaterial = require(ReplicatedStorage.API.GetMaterial)
local BehaviourTypes = require(script.Parent.BehaviourTypes)
local Checks = require(script.Parent.Checks)
local Types = require(ReplicatedStorage.API.Types)
local RoundInfoUI = require(ReplicatedStorage.Shared.Interface.GameState.RoundInfoUI)
local CreateEmptyPart = require(ReplicatedStorage.Shared.RoundRule.Common.CreateEmptyPart)
local PlaySound = require(ReplicatedStorage.API.PlaySound)
local LocalCharacter = require(ReplicatedStorage.Shared.Character.LocalCharacter)
local Aim = require(ReplicatedStorage.Shared.Combat.Aim)
local BulletTracer = require(ReplicatedStorage.Shared.Combat.BulletTracer)
local HitSounds = require(ReplicatedStorage.Shared.Combat.HitSounds)
local Viewmodel = require(ReplicatedStorage.Shared.Combat.Viewmodel)

local Client = {}

local random = Random.new(workspace:GetServerTimeNow())
function Client.GetRaycastDirection(direction: Vector3, spread: number): Vector3
	local spreadVector = Vector3.new(random:NextNumber(-spread, spread), random:NextNumber(-spread, spread), random:NextNumber(-spread, spread))
	return (direction + spreadVector).Unit
end

function Client.DeriveTargetPosition(origin: Vector3, direction: Vector3, range: number): Vector3
	return origin + (direction.Unit * range)
end

function Client.DeductAmmo(item: Types.Item): ()
	if not item.Ammo then
		return
	end

	item.Ammo -= 1
	RoundInfoUI.UpdateAmmo()
end

function Client.ApplyInterval(item: Types.Item, action: "Primary" | "Alternate"): ()
	if action == "Primary" and item.PrimaryInterval then
		item.PrimaryLastUse = os.clock()
	elseif action == "Alternate" and item.AlternateInterval then
		item.AlternateLastUse = os.clock()
	end
end

function Client.GetDefaultRaycastParams(char: Instance): RaycastParams
	local params = RaycastParams.new()
	params.FilterDescendantsInstances = {char}
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.IgnoreWater = true
	params.CollisionGroup = "WeaponHitTargets"

	return params
end

function Client.Hitscan(
	params: RaycastParams,
	origin: Vector3,
	direction: Vector3,
	range: number,
	checkInitialOverlap: boolean?,
	fallbackToBlockcast: boolean?
): BehaviourTypes.HitscanResult
	local parts: {BasePart}?
	if checkInitialOverlap then
		local overlapParams = OverlapParams.new()
		overlapParams.FilterDescendantsInstances = params.FilterDescendantsInstances
		overlapParams.FilterType = params.FilterType
		overlapParams.CollisionGroup = params.CollisionGroup

		local boundPart = CreateEmptyPart(workspace.CurrentCamera.CFrame)
		boundPart.Size = Vector3.new(0.1, 0.1, 0.1)
		parts = workspace:GetPartsInPart(boundPart, overlapParams)
	end

	direction *= range
	local result = workspace:Raycast(origin, direction, params)

	if not result and fallbackToBlockcast then
		result = workspace:Blockcast(CFrame.new(origin), Vector3.one * 1.5, direction, params)
	end

	local part = if result then result.Instance else if parts and parts[1] then parts[1] else nil

	local position =
		if result then
			result.Position
		elseif part then
			part:GetClosestPointOnSurface(origin)
		else
			Client.DeriveTargetPosition(origin, direction, range)

	local normal = if result then result.Normal else (origin - position).Unit
	local relativeCFrame = if part then part.CFrame:ToObjectSpace(CFrame.new(position)) else nil

	if part and relativeCFrame then
		return {
			Hit = {
				Part = part,
				Normal = normal,
				RelativeCFrame = relativeCFrame,
			},
			Position = position,
		}
	end

	return {
		Position = position,
	}
end

function Client.MuzzleFlash(item: Types.Item): ()
	if item.HasMuzzleFlash then
		Viewmodel.MuzzleFlash()
	end
end

function Client.Recoil(item: Types.Item): ()
	Viewmodel.Recoil(item)
end

function Client.PlayEmptyClipSound(): ()
	PlaySound(ReplicatedStorage.Assets.ItemSounds.EmptyClip)
end

function Client.PrimaryFire(item: Types.Item, origin: Vector3, direction: Vector3): ()
	local char = LocalCharacter.Character()
	if not char then
		return
	end

	if not Checks.Ammo(item) or not Checks.Scoped(item, Aim.IsAiming()) then
		Client.PlayEmptyClipSound()
		return
	end

	if not Checks.Reloading(item) then
		return
	end

	Client.DeductAmmo(item)
	Client.MuzzleFlash(item)
	Client.Recoil(item)

	if not item.IsProjectileSimulated then
		local params = Client.GetDefaultRaycastParams(char)

		local hits = {}
		for i = 1, item.ProjectileCount or 1 do
			local spreadDirection = Client.GetRaycastDirection(direction, item.Spread or 0)
			local result = Client.Hitscan(params, origin, spreadDirection, item.MaxDistance or 10000, item.CheckInitialIntersection, item.CheckInitialIntersection)

			local targetPosition = result and result.Position or Client.DeriveTargetPosition(origin, direction, item.MaxDistance or 10000)
			if item.Projectile then
				BulletTracer(item.Projectile, item.ProjectileSpeed or 100, origin, targetPosition)
			end

			table.insert(hits, result)

			if not result.Hit then
				continue
			end

			if not GetMapObject(result.Hit.Part, "Character") then
				PlaySound(HitSounds[GetMaterial(result.Hit.Part)] or HitSounds.Default, targetPosition, nil, {
					RollOffMaxDistance = 20,
				})
			end
		end

		local data: BehaviourTypes.Request = hits

		item:SetServerData("Primary", data)
	end
end

return Client