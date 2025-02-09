local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local BulletTracer = require(ReplicatedStorage.BulletTracer)
local CombatTypes = require(ReplicatedStorage.CombatTypes)
local PlayPositionalSound = require(ReplicatedStorage.PlayPositionalSound)
local Types = require(ReplicatedStorage.RoundRule.Types)
local ShatterGlass = require(ReplicatedStorage.ShatterGlass)
local module = {}

local MAX_SHOOTER_DISTANCE = 15
local MAX_TARGET_DISTANCE = 10
local STATIC_OBSCURE_DISTANCE = 0.05					

local function isOf(part: BasePart, name: string, match: boolean?): boolean?
	local accessoryWeld = part:FindFirstChild("AccessoryWeld") :: Weld
	if accessoryWeld and accessoryWeld.Part1 and accessoryWeld.Part1.Name == name then
		if accessoryWeld.Part1.Name == name or (match and (accessoryWeld.Part1.Name:match(name) ~= nil)) then
			return true
		end
	end
	return (part.Name == name) or (part:FindFirstAncestor(name) ~= nil) or (match and (part.Name:match(name) ~= nil))
end

local function getItemDamage(item: Types.AnyWeapon | Types.ExplosionParams, hitPart: BasePart): number
	assert(item.Kind ~= "Grenade", "Cannot get damage for grenade")

	if item.Kind == "ExplosionParams" then
		return (item.Definition.FalloffEnd - (hitPart.Position - item.Position).Magnitude) / item.Definition.FalloffEnd * item.Definition.Damage
	end

	local dmg = item.Definition.Damage
	if typeof(dmg) == "number" then
		return dmg
	end

	local hitArea: "Body" | "Head" | "Limb" = "Limb"
	if isOf(hitPart, "Head") then
		hitArea = "Head"
	elseif isOf(hitPart, "Torso", true) or isOf(hitPart, "HumanoidRootPart") then
		hitArea = "Body"
	else
		hitArea = "Limb"
	end

	return dmg[hitArea]
end

local function tryGetParticipantFromPart(round: Types.Round, part: BasePart): Types.Participant?
	local model = part:FindFirstAncestorOfClass("Model")
	if not model then
		return
	end

	local player = Players:GetPlayerFromCharacter(model)
	if not player then
		return
	end

	return round:GetParticipant(player.Name)
end

-- only considers static map
local function validateRaycast(item: Types.AnyItem, by: Types.Participant, origin: Vector3, destination: Vector3, target: BasePart?, targetCenterPosition: Vector3?): CombatTypes.ValidateRaycastResult
	local char = by:GetCharacter()
	if not char then
		return "ShooterTooFar"
	end

	local head = char:WaitForChild("Head")
	if not head or not head:IsA("BasePart") or (head.Position - origin).Magnitude > MAX_SHOOTER_DISTANCE then
		return "ShooterTooFar"
	end

	if target and (target.Position - assert(targetCenterPosition)).Magnitude > MAX_TARGET_DISTANCE then
		return "TargetTooFar"
	end

	if item.Kind == "Melee" and (destination - origin).Magnitude > (item.Definition.MaxDistance + 0.1) then
		return "TargetTooFar"
	end

	if target then
		local params = RaycastParams.new()
		params.FilterDescendantsInstances = {by.Round:GetMap().StaticMap}
		params.FilterType = Enum.RaycastFilterType.Include
		params.IgnoreWater = true

		-- We need to check the distance between the hit target and the actual intended target.
		-- Reason being, some maps unfortunately feature Z-fighting, leading to hits being rejected as they were "obscured" by a part in the same exact place.
		-- We do still set the actual target as the hit result though

		local result = workspace:Raycast(origin, destination - origin, params)
		if result and result.Instance ~= target then
			if (result.Position - destination).Magnitude > STATIC_OBSCURE_DISTANCE then
				return "StaticObscured"
			end
		end
	end

	return "Success"
end

local function validateItemUsage(by: Types.Participant, item: Types.AnyItem, requestKind: string): CombatTypes.ValidateItemUsageResult
	if (item.Kind == "Grenade") and (requestKind :: string ~= "PrimaryFireThrowRequest") then
		return "OtherError"
	elseif (item.Kind == "Gun" or item.Kind == "Melee") and (requestKind :: string ~= "PrimaryFireRaycastRequest") then
		return "OtherError"
	end
	
	if by:GetHealth() <= 0 then
		return "Dead"
	end

	if by:GetEquippedItem() ~= item then
		return "NotEquipped"
	end

	if item.Kind == "Gun" and item.Ammo <= 0 then
		return "NotEnoughAmmo"
	end

	if item.Kind == "Gun" and item.IsReloading then
		return "Reloading"
	end

	return "Success"
end

local function onParticipantHit(item: Types.GunMeleeWeapon | Types.ExplosionParams, by: Types.Participant?, victim: Types.Participant, hitPart: BasePart, hitPosition: Vector3): ()
	if item.Kind ~= "ExplosionParams" then
		assert(by, "by must not be nil")
	end

	local damage = getItemDamage(item, hitPart)
	local willDie = victim:GetHealth() <= damage
	local hitFunction = item.Definition.BeforeHitParticipant
	if hitFunction then
		if not hitFunction(item :: Types.GunMeleeWeapon, by :: Types.Participant, victim, willDie) then
			return
		end
	end

	victim:TryTakeDamage({
		Amount = damage,
		Source = if item.Kind == "ExplosionParams" then "Explode" else item,

		IsHeadshot = hitPart.Name == "Head",
		Attacker = by,
	})
end

local function onWindowHit(item: Types.GunMeleeWeapon | Types.ExplosionParams, by: Types.Participant?, hitPart: BasePart, hitPosition: Vector3): ()
	ShatterGlass(hitPart)
end

local function onPropHit(item: Types.GunMeleeWeapon | Types.ExplosionParams, by: Types.Participant?, prop: Types.Prop, hitPart: BasePart, hitPosition: Vector3): ()
	local health = prop:GetHealth()
	if not health then
		return
	end

	local damage = getItemDamage(item, hitPart)
	local willDie = prop:GetHealth() <= damage
	local hitFunction = item.Definition.BeforeHitProp
	if hitFunction then
		if not hitFunction(item :: Types.GunMeleeWeapon, by :: Types.Participant, prop, willDie) then
			return
		end
	end

	prop:TryTakeDamage({
		Amount = getItemDamage(item, hitPart),
		Source = if item.Kind == "ExplosionParams" then "Explode" else item,

		Attacker = by,
	})
end

local function onPartHit(item: Types.GunMeleeWeapon | Types.ExplosionParams, by: Types.Participant, hitPart: BasePart, hitPosition: Vector3, normal: Vector3?): ()
	local round = by.Round
	local map = round:GetMap()

	local victim = tryGetParticipantFromPart(round, hitPart)
	local prop = round:GetProp(hitPart)
	if victim then
		return onParticipantHit(item, by, victim, hitPart, hitPosition)
	elseif hitPart:IsDescendantOf(map.Windows) then
		return onWindowHit(item, by, hitPart, hitPosition)
	elseif prop then
		return onPropHit(item, by, prop, hitPart, hitPosition)
	end

	if normal and item.Kind == "Gun" then
		ReplicatedStorage.ServerClient.MakeBulletHole:FireAllClients(hitPart, hitPart.CFrame:ToObjectSpace(CFrame.new(hitPosition)), normal)
	end
end

function module.CreateExplosion(round: Types.Round, params: Types.ExplosionParams): ()
    local explosion = Instance.new("Explosion")

    local info = params.Definition

    explosion.Position = params.Position
    explosion.BlastRadius = info.VisualRadius
    explosion.BlastPressure = info.Pressure

    explosion.DestroyJointRadiusPercent = 0
    explosion.ExplosionType = Enum.ExplosionType.NoCraters

    local folder = workspace:FindFirstChild("Explosions") or Instance.new("Folder")
    assert(folder:IsA("Folder"), "Explosions is not a folder")
    folder.Name = "Explosions"
    folder.Parent = workspace

	PlayPositionalSound(ServerStorage.Explosion, params.Position)

    explosion.Parent = folder

	local hits: {Types.Participant | Types.Prop} = {}
    for _, v in workspace:GetPartBoundsInRadius(params.Position, info.FalloffEnd) do
        local prop = round:GetProp(v)
		if prop then
			if table.find(hits, prop) then
				continue
			end
			table.insert(hits, prop)
			onPropHit(params, params.Attacker, prop, v, v.Position)
			continue
		end

		local participant = tryGetParticipantFromPart(round, v)
		if participant then
			if table.find(hits, participant) then
				continue
			end
			table.insert(hits, participant)
			onParticipantHit(params, params.Attacker, participant, v, v.Position)
			continue
		end
    end
end

function module.PrimaryFire(by: Types.Participant, request: CombatTypes.PrimaryFireRequest): CombatTypes.ValidateItemUsageResult
	local item = by:GetEquippedItem()
	if not item or item.Definition.Name ~= request.ItemName then
		return "NotEquipped"
	end

	local validateItemUsageResult = validateItemUsage(by, item, request.Kind)
	if validateItemUsageResult ~= "Success" then
		return validateItemUsageResult :: CombatTypes.ValidateItemUsageResult
	end

	local definition = item.Definition
	if definition.Kind == "Gun" or definition.Kind == "Melee" or definition.Kind == "Grenade" then
		local char = by:GetCharacter()
		if not char then
			return "ShooterTooFar"
		end

		local sound = Instance.new("Sound")
		sound.SoundId = definition.AttackSound
		sound.PlayOnRemove = true
		sound.Parent = char.PrimaryPart
		sound:Destroy()
	end

	if item.Kind == "Gun" then
		item.Ammo -= 1
	elseif item.Kind == "Grenade" then
		by:RemoveItem(item)
	end

	if request.Kind == "PrimaryFireRaycastRequest" then
		for i, v in ipairs(request.Raycasts) do
			if i > (if item.Kind == "Gun" then item.Definition.BulletsPerShot or 1 else 1) then
				break
			end

			if definition.Kind == "Gun" and definition.Projectile then
				BulletTracer(definition.Projectile, definition.ProjectileSpeed or 100, request.Origin, v.Destination)
			end

			local validateRaycastResult = validateRaycast(item, by, request.Origin, v.Destination, v.HitPart, v.HitPartCenterPosition)
			if validateRaycastResult ~= "Success" then
				return validateRaycastResult :: CombatTypes.ValidateRaycastResult
			end

			if item.Kind ~= "Item" and item.Kind ~= "Grenade" and v.HitPart then
				onPartHit(item, by, v.HitPart, v.Destination, v.Normal)
			end
		end
	elseif request.Kind == "PrimaryFireThrowRequest" then
		if item.Kind ~= "Grenade" then
			return "OtherError"
		end

		local projectile = item.Definition.Projectile:Clone()
		projectile.Anchored = false
		projectile.CollisionGroup = "Grenades"

		by:TryThrowAssembly(projectile, 60, workspace.Projectiles, request.Origin, request.Direction)

		task.wait(item.Definition.FuseTime)
		projectile:Destroy()

		local explosionParams: Types.ExplosionParams = {
			Kind = "ExplosionParams",
			Definition = item.Definition.ExplosionInfo,
			Attacker = by,
			Position = projectile.Position,
		}
		module.CreateExplosion(by.Round, explosionParams)

		if item.Definition.OnExplode then
			item.Definition.OnExplode(item, by, projectile)
		end
	elseif request.Kind == "PrimaryFireItemRequest" then
		if item.Kind ~= "Item" then
			return "OtherError"
		end

		if not item.Definition.PrimaryFire then
			return "OtherError"
		end

		item.Definition.PrimaryFire(item, by, request.Direction)
	end

	return "Success"
end

function module.AlternateFire(by: Types.Participant, request: CombatTypes.AlternateFireRequest): CombatTypes.ValidateItemUsageResult
	local item = by:GetEquippedItem()
	if not item or item.Definition.Name ~= request.ItemName then
		return "NotEquipped"
	end

	local validateItemUsageResult = validateItemUsage(by, item, request.Kind)
	if validateItemUsageResult ~= "Success" then
		return validateItemUsageResult :: CombatTypes.ValidateItemUsageResult
	end

	if item.Kind ~= "Item" then
		return "OtherError"
	end

	local func = (item :: Types.Item).Definition.AlternateFire
	if not func then
		return "OtherError"
	end

	func(item, by, request.Direction)

	return "Success"
end

return module