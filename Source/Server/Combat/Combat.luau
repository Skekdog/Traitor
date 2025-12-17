local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local SoundService = game:GetService("SoundService")
local GetMaterial = require(ReplicatedStorage.API.GetMaterial)
local Impulse = require(ReplicatedStorage.API.Impulse)
local BulletTracer = require(ReplicatedStorage.Shared.Combat.BulletTracer)
local CombatTypes = require(ReplicatedStorage.Shared.Combat.CombatTypes)
local HitSounds = require(ReplicatedStorage.Shared.Combat.HitSounds)
local GetMapObjectWithTag = require(ReplicatedStorage.Shared.RoundRule.Common.GetMapObjectWithTag)
local PlaySound = require(ReplicatedStorage.Shared.RoundRule.Common.PlaySound)
local ExplosionParams = require(ReplicatedStorage.Shared.RoundRule.ExplosionParams)
local RunBeforeHit = require(ReplicatedStorage.Shared.RoundRule.RunBeforeHit)
local Types = require(ReplicatedStorage.Shared.RoundRule.Types)
local module = {}

local MAX_SHOOTER_DISTANCE = 15
local MAX_TARGET_DISTANCE = 10
local STATIC_OBSCURE_DISTANCE = 0.05

local NEAR_MISS_RADIUS = 0.25 -- note this is a RADIUS, so it gets doubled when used
local NEAR_MISS_SD_DURATION = 5

local nearMissSound = Instance.new("Sound")
nearMissSound.SoundId = "rbxassetid://98905989782853"
nearMissSound.Parent = ReplicatedStorage.Assets

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
		assert(item.Definition.FalloffEnd ~= 0, "Cannot divide by 0")
		return ((item.Definition.FalloffEnd - math.max((hitPart.Position - item.Position).Magnitude - item.Definition.FalloffBegin, 0)) / item.Definition.FalloffEnd) * item.Definition.Damage
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

-- only considers static map
local function validatePrimaryFire(item: Types.AnyItem, by: Types.Participant, origin: Vector3, destination: Vector3, target: BasePart?, targetCenterPosition: Vector3?): CombatTypes.ValidatePrimaryFire
	if item.PreventPrimaryFire then
		return "PrimaryFireDisabled"
	end

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
		params.FilterDescendantsInstances = {by.Round:GetMap().Structure.Static}
		params.CollisionGroup = "WeaponHitTargets"
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
	elseif (item.Kind == "Gun") and (requestKind :: string ~= "PrimaryFireRaycastRequest" and requestKind :: string ~= "PrimaryFireItemRequest") then
		return "OtherError"
	elseif (item.Kind == "Melee") and (requestKind :: string ~= "PrimaryFireRaycastRequest" and requestKind :: string ~= "AlternateFireItemRequest") then
		return "OtherError"
	end

	if requestKind == "AlternateFireItemRequest" and item.PreventAlternateFire then
		return "AlternateFireDisabled"
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

	if item.Kind == "Grenade" and by.Round:IsPreGame() then
		return "PreGame"
	end

	return "Success"
end

local function onParticipantHit(item: Types.GunMeleeWeapon | Types.ExplosionParams, round: Types.Round, by: Types.Participant?, victim: Types.Participant, hitPart: BasePart, hitPosition: Vector3, grenade: Types.GrenadeWeapon?, origin: Vector3, impulse: Vector3?): ()
	if item.Kind ~= "ExplosionParams" then
		assert(by, "by must not be nil")
	end

	local damage = getItemDamage(item, hitPart)
	local params: Types.DamageParams = {
		Amount = damage,
		Source = (if item.Kind == "ExplosionParams" then "Explode" else item) :: Types.DamageSource,
		IsHeadshot = item.Kind == "Gun" and isOf(hitPart, "Head"),
		Attacker = by,

		HitPosition = hitPosition,
		Origin = origin,
		Direction = (hitPosition - origin).Unit,
		HitPart = hitPart,
	}

	if item.Kind == "ExplosionParams" then
		params.IgnoreKarma = item.Definition.IgnoreKarma
		params.IgnoreScore = item.Definition.IgnoreScore
		params.IgnoreSelfDefense = item.Definition.IgnoreSelfDefense
	end

	if not item:RunBeforeHit(round, hitPart, params) then
		return
	end

	if item.Kind ~= "ExplosionParams" then
		item:RunOnHitClient(victim, hitPart)
	end

	if grenade then
		grenade:RunOnHitClient(victim, hitPart)
	end

	if victim.Round:IsPreGame() then
		return
	end

	local willDie = params.Amount >= victim:GetHealth()
	if willDie then
		victim.Extras.CombatImpulse = impulse
	end

	victim:TryTakeDamage(params, item.Kind == "ExplosionParams")
end

local function onPropHit(item: Types.GunMeleeWeapon | Types.ExplosionParams, round: Types.Round, by: Types.Participant?, prop: Types.Prop | Types.Interactable, hitPart: BasePart, hitPosition: Vector3, origin: Vector3): ()
	if item.Kind ~= "ExplosionParams" then
		assert(by, "by must not be nil")
	end

	local damage = getItemDamage(item, hitPart)
	local params = {
		Amount = damage,
		Source = (if item.Kind == "ExplosionParams" then "Explode" else item) :: Types.DamageSource,

		Attacker = by,

		HitPosition = hitPosition,
		Direction = (hitPosition - origin).Unit,
		Origin = origin,
		HitPart = hitPart,
	}

	if not item:RunBeforeHit(round, hitPart, params) then
		return
	end

	(prop :: Types.Prop):TryTakeDamage(params)
end

local function onPartHit(item: Types.GunMeleeWeapon | Types.ExplosionParams, by: Types.Participant, hitPart: BasePart, hitPosition: Vector3, normal: Vector3?, origin: Vector3, relativeHitCFrame: CFrame?): "Part" | "Prop" | "Participant"?
	if not hitPart.Parent then
		return nil -- ?? No idea how but I had an error where the hitPart was unparented. Somehow.
	end
	local round = by.Round

	local impulse: Vector3?
	if (item.Kind == "Gun" or item.Kind == "Melee") and item.Definition.ImpulseForce then
		impulse = item.Definition.ImpulseForce * (hitPosition - origin).Unit
		Impulse.ApplyImpulse(hitPart, assert(impulse), true, hitPosition, by)
	end

	if hitPart and not hitPart:IsDescendantOf(workspace.Characters) then
		for _, v in Players:GetPlayers() do
			if v ~= by.Player then
				PlaySound(HitSounds[GetMaterial(hitPart)] or HitSounds.Default, hitPosition, nil, {
					RollOffMinDistance = 0,
					RollOffMaxDistance = 20,
				}, v)
			end
		end
	end

	local MapObject = GetMapObjectWithTag(hitPart, "Prop")
	local prop = round:GetProp(MapObject or hitPart)
	local interactable = round:GetInteractable(MapObject or hitPart)

	local propLike = prop or interactable

	if propLike then
		onPropHit(item, round, by, propLike, hitPart, hitPosition, origin)
		return "Prop"
	else
		local char = GetMapObjectWithTag(hitPart, "Character")
		local victim = if char and char:IsA("Model") then round:GetParticipant(char) else nil
		if victim then
			onParticipantHit(item, round, by, victim, hitPart, hitPosition, nil, origin, impulse)
			return "Participant"
		end
	end

	local params: Types.DamageParams = {
		Amount = getItemDamage(item, hitPart),
		Source = (if item.Kind == "ExplosionParams" then "Explode" else item) :: Types.DamageSource,

		Attacker = by,

		HitPosition = hitPosition,
		Direction = (hitPosition - origin).Unit,
		Origin = origin,
		HitPart = hitPart,
	}

	RunBeforeHit(item, by.Round, hitPart, params)

	if normal and item.Kind == "Gun" then
		if relativeHitCFrame and relativeHitCFrame.Position.Magnitude <= hitPart.ExtentsSize.Magnitude * 1.1 then
			ReplicatedStorage.Remotes.ServerClient.MakeBulletHole:FireAllClients(hitPart, relativeHitCFrame, normal)
		end
	end

	return "Part"
end

function module.CreateExplosion(round: Types.Round, params: Types.ExplosionParams, grenade: Types.GrenadeWeapon?, sound: Sound?): ()
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

	PlaySound(sound or ServerStorage.Assets.Explosion, params.Position, nil, {SoundGroup = SoundService.AllSounds :: SoundGroup})

    explosion.Parent = folder

	local hits: {Types.Participant | Types.Prop | Types.Interactable} = {}
    for _, v in workspace:GetPartBoundsInRadius(params.Position, info.FalloffEnd) do
		if not v:IsDescendantOf(workspace) then
			continue -- stupid bullshit
		end
		local propObject = GetMapObjectWithTag(v, "Prop")
		if propObject then
			local prop = round:GetProp(propObject)
			if prop then
				if table.find(hits, prop) then
					continue
				end
				table.insert(hits, prop)
				onPropHit(params, round, params.Attacker, prop, v, v.Position, params.Position)
				continue
			end

			local interactable = round:GetInteractable(propObject)
			if interactable then
				if table.find(hits, interactable) then
					continue
				end
				table.insert(hits, interactable)
				onPropHit(params, round, params.Attacker, interactable, v, v.Position, params.Position)
				continue
			end
		end

		local char = GetMapObjectWithTag(v, "Character")
		local participant = if char and char:IsA("Model") then round:GetParticipant(char) else nil

		local impulse = (v.Position - params.Position).Unit * info.Pressure / 1000

		if participant then
			if table.find(hits, participant) then
				continue
			end
			table.insert(hits, participant)
			onParticipantHit(params, round, params.Attacker, participant, v, v.Position, grenade, params.Position, impulse)
		end

		Impulse.ApplyImpulse(v, impulse, true, nil, params.Attacker)
    end
end

local nearMissOverlapParams = OverlapParams.new()
nearMissOverlapParams.FilterDescendantsInstances = {workspace.Characters}
nearMissOverlapParams.FilterType = Enum.RaycastFilterType.Include

-- I think it makes more sense to do this on the server than on the client?
-- I'm not honestly sure though
local function applyNearMissSelfDefense(origin: Vector3, destination: Vector3, attacker: Types.Participant): ()
	local round = attacker.Round

	local processed: {[Model]: true?} = {}

	local length = (destination - origin).Magnitude
	local cframe = CFrame.new(origin, destination) * CFrame.new(0, 0, -length / 2)

	local size = Vector3.one * NEAR_MISS_RADIUS * 2 * Vector3.new(1, 1, length)

	for _, part in workspace:GetPartBoundsInBox(cframe, size, nearMissOverlapParams) do
		local model = part:FindFirstAncestorOfClass("Model")
		if not model or processed[model] then
			continue
		end

		processed[model] = true

		local target = round:GetParticipant(model)
		if not target or target == attacker then
			continue
		end

		target:AddSelfDefenseEntry({
			Against = attacker,
			Duration = NEAR_MISS_SD_DURATION,
		})

		PlaySound(nearMissSound, nil, part, nil, target.Player)
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

		if definition.AttackSound then
			for _, v in Players:GetPlayers() do
				if v ~= by.Player then
					PlaySound(definition.AttackSound, nil, char.PrimaryPart, nil, v)
				end
			end
		end
	end

	if item.Kind == "Gun" then
		item.Ammo -= 1
	end

	if definition.Kind == "Melee" then
		local id = assert(tonumber((definition.AttackAnimation :: string):split("://")[2]), "Invalid attack animation: " .. tostring(definition.AttackAnimation))
		by:TryPlayAnimation(id, "MeleeAttack")
	end

	if request.Kind == "PrimaryFireRaycastRequest" then
		for i, v in ipairs(request.Raycasts) do
			if i > (if item.Kind == "Gun" then item.Definition.BulletsPerShot or 1 else 1) then
				break
			end

			if definition.Kind == "Gun" and definition.Projectile then
				BulletTracer(definition.Projectile, definition.ProjectileSpeed or 100, request.Origin, v.Destination, by.Player)
			end

			local validateRaycastResult = validatePrimaryFire(item, by, request.Origin, v.Destination, v.HitPart, v.HitPartCenterPosition)
			if validateRaycastResult ~= "Success" then
				return validateRaycastResult :: CombatTypes.ValidatePrimaryFire
			end

			if item.Kind == "Gun" and not item.Definition.IsSilent then
				applyNearMissSelfDefense(request.Origin, v.Destination, by)
			end

			if item.Kind ~= "Item" and item.Kind ~= "Grenade" and v.HitPart then
				onPartHit(item, by, v.HitPart, v.Destination, v.Normal, request.Origin, v.RelativeHitCFrame)
			end
		end
	elseif request.Kind == "PrimaryFireThrowRequest" then
		if item.Kind ~= "Grenade" then
			return "OtherError"
		end

		by:RemoveItem(item)

		local projectile = item.Definition.Projectile:Clone()
		projectile.Anchored = false
		projectile.CollisionGroup = "Grenades"

		by:TryThrowAssembly(projectile, 35, workspace.Projectiles, request.Origin, request.Direction, true)

		local function explode()
			projectile:Destroy()

			local explosionParams = ExplosionParams.new(item.Definition.ExplosionInfo, projectile.Position, by)
			module.CreateExplosion(by.Round, explosionParams, item)

			if item.Definition.OnExplode then
				item.Definition.OnExplode(item, by, projectile)
			end
		end

		if item.Definition.FuseTime < 0 then
			local char = by:GetCharacter()
			local startTime = os.clock()

			local maxBounces = item.Definition.MaxBounces or 1
			local bounces = 0

			projectile.Touched:Connect(function(part)
				if (os.clock() - startTime < 0.5 and char and part:IsDescendantOf(char)) or not PhysicsService:CollisionGroupsAreCollidable(projectile.CollisionGroup, part.CollisionGroup) then
					return
				end

				bounces += 1
				if bounces >= maxBounces then
					explode()
				end
			end)
		else
			task.wait(item.Definition.FuseTime)
			explode()
		end
	elseif request.Kind == "PrimaryFireItemRequest" then
		if item.Kind ~= "Item" and item.Kind ~= "Gun" then
			return "OtherError"
		end

		if item.Kind == "Item" then
			if not item.Definition.PrimaryFireServer then
				return "OtherError"
			end

			item.Definition.PrimaryFireServer(item, "Primary", request.Origin, request.Direction, by)
		else
			if not item.Definition.IsPhysicallySimulated or not item.Definition.Projectile or not item.Definition.ProjectileSpeed then
				return "OtherError"
			end

			local projectile = item.Definition.Projectile:Clone()
			projectile.CollisionGroup = "WeaponHitTargets"
			projectile.Parent = workspace.Projectiles

			projectile:SetNetworkOwner(nil)
			by:TryThrowAssembly(projectile, item.Definition.ProjectileSpeed, nil, request.Origin, request.Direction)

			local char = by:GetCharacter()

			local bounces = 0
			local maxBounces = item.Definition.MaxBounces or 1

			local startTime = os.clock()
			projectile.Touched:Connect(function(part)
				if (os.clock() - startTime < 0.5 and char and part:IsDescendantOf(char)) or not PhysicsService:CollisionGroupsAreCollidable(projectile.CollisionGroup, part.CollisionGroup) then
					return
				end

				bounces += 1

				local result = onPartHit(item, by, part, projectile.Position, nil, request.Origin)
				if result == "Participant" or bounces >= maxBounces then
					projectile:Destroy()
				end
			end)
		end
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

	if item.Kind ~= "Item" and item.Kind ~= "Melee" then
		return "OtherError"
	end

	local func = (item :: Types.Item).Definition.AlternateFireServer
	if not func then
		return "OtherError"
	end

	func(item :: Types.Item, "Alternate", request.Origin, request.Direction, by)

	return "Success"
end

return module