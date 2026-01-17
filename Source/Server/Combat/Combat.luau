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
local ForEachPart = require(ReplicatedStorage.Shared.RoundRule.Common.ForEachPart)
local GetMapObjectWithTag = require(ReplicatedStorage.Shared.RoundRule.Common.GetMapObjectWithTag)
local GetPrimaryPart = require(ReplicatedStorage.Shared.RoundRule.Common.GetPrimaryPart)
local PlaySound = require(ReplicatedStorage.Shared.RoundRule.Common.PlaySound)
local ExplosionParams = require(ReplicatedStorage.Shared.RoundRule.ExplosionParams)
local Replication = require(ReplicatedStorage.Shared.RoundRule.Replication)
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

local function getItemDamage(item: Types.Item | Types.ExplosionParams, hitPart: BasePart, origin: Vector3): number
	local data = if item.Kind == "ExplosionParams" then item.Definition :: Types.ExplosionInfo else item :: Types.Item

	local baseDamage = data.Damage
	if not baseDamage then
		return 0
	end

	local damage = 0
	if typeof(baseDamage) == "table" then
		local hitArea: "Body" | "Head" | "Limb" = "Limb"
		if isOf(hitPart, "Head") then
			hitArea = "Head"
		elseif isOf(hitPart, "Torso", true) or isOf(hitPart, "HumanoidRootPart") then
			hitArea = "Body"
		else
			hitArea = "Limb"
		end
		damage = baseDamage[hitArea]
	else
		damage = baseDamage
	end

	if data.FalloffEnd then
		damage *= (data.FalloffEnd - math.max((hitPart.Position - origin).Magnitude - (data.FalloffStart or 0), 0)) / data.FalloffEnd
	end

	return damage
end

-- only considers static map
local function validateRaycast(item: Types.Item, by: Types.Participant, origin: Vector3, destination: Vector3, target: BasePart?, targetCenterPosition: Vector3?): CombatTypes.ValidateUsageResult
	if target and (target.Position - assert(targetCenterPosition)).Magnitude > MAX_TARGET_DISTANCE then
		return "TargetTooFar"
	end

	if item.MaxDistance and (destination - origin).Magnitude > (item.MaxDistance + 0.1) then
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

local function validateItemUsage(by: Types.Participant, item: Types.Item, request: CombatTypes.Request): CombatTypes.ValidateUsageResult
	if request.Action == "Primary" and not item.PrimaryFireServer and not item.UseAttack then
		return "OtherError"
	elseif request.Action == "Alternate" and not item.AlternateFireServer then
		return "OtherError"
	end

	if request.Action == "Primary" and item.PrimaryDisabled then
		return "PrimaryFireDisabled"
	elseif request.Action == "Alternate" and item.AlternateDisabled then
		return "AlternateFireDisabled"
	end

	if by:GetHealth() <= 0 then
		return "Dead"
	end

	local char = by:GetCharacter()
	if not char then
		return "OriginTooFar"
	end

	local head = char:WaitForChild("Head")
	if not head or not head:IsA("BasePart") or (head.Position - request.Origin).Magnitude > MAX_SHOOTER_DISTANCE then
		return "OriginTooFar"
	end

	if by:GetEquippedItem() ~= item then
		return "NotEquipped"
	end

	if request.Action == "Primary" and item.Ammo and item.Ammo <= 0 and item.UseAttack then
		return "NotEnoughAmmo"
	end

	if item.IsReloading and item.UseAttack then
		return "Reloading"
	end

	if item.PregameDisable and by.Round:IsPreGame() then
		return "Pregame"
	end

	return "Success"
end

local function onParticipantHit(item: Types.Item | Types.ExplosionParams, by: Types.Participant?, victim: Types.Participant, hitPart: BasePart, hitPosition: Vector3, origin: Vector3, impulse: Vector3?, originalItem: Types.Item?): ()
	if item.Kind ~= "ExplosionParams" then
		assert(by, "by must not be nil")
	end

	if victim.Round:IsPreGame() then
		return
	end

	local data = if item.Kind == "ExplosionParams" then item.Definition else item

	local damage = getItemDamage(item, hitPart, origin)

	local params: Types.DamageParams = {
		Amount = damage,
		Source = (if item.Kind == "ExplosionParams" then "Explode" else item) :: Types.DamageSource,
		IsHeadshot = item.Kind == "Item" and item.CanHeadshot and isOf(hitPart, "Head"),
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

	if data.BeforeHitParticipant then
		if not (data.BeforeHitParticipant :: Types.BeforeHitParticipant)(item :: Types.Item, params, victim) then
			return
		end
	end

	if originalItem and originalItem.OnHitClient then
		Replication.RunOnHitClient(originalItem, victim, hitPart)
	end

	local willDie = params.Amount >= victim:GetHealth()
	if willDie then
		victim.Extras.CombatImpulse = impulse
	end

	victim:TryTakeDamage(params, item.Kind == "ExplosionParams")
end

local function onPropHit(item: Types.Item | Types.ExplosionParams, by: Types.Participant?, prop: Types.Prop | Types.Interactable, hitPart: BasePart, hitPosition: Vector3, origin: Vector3): ()
	if item.Kind ~= "ExplosionParams" then
		assert(by, "by must not be nil")
	end

	local damage = getItemDamage(item, hitPart, origin)

	local params = {
		Amount = damage,
		Source = (if item.Kind == "ExplosionParams" then "Explode" else item) :: Types.DamageSource,

		Attacker = by,

		HitPosition = hitPosition,
		Direction = (hitPosition - origin).Unit,
		Origin = origin,
		HitPart = hitPart,
	}

	local data = if item.Kind == "Item" then item else item.Definition

	if data.BeforeHitProp then
		if not (data.BeforeHitProp :: Types.BeforeHitProp)(item :: Types.Item, params, prop :: Types.Prop) then
			return
		end
	end

	(prop :: Types.Prop):TryTakeDamage(params)
end

local function onPartHit(item: Types.Item | Types.ExplosionParams, by: Types.Participant, hitPart: BasePart, hitPosition: Vector3, normal: Vector3?, origin: Vector3, relativeHitCFrame: CFrame?, originalItem: Types.Item?): "Part" | "Prop" | "Participant"?
	if not hitPart.Parent then
		return nil -- ?? No idea how but I had an error where the hitPart was unparented. Somehow.
	end

	local round = by.Round

	local impulse: Vector3?
	if item.Kind == "Item" and item.ImpulseForce then
		impulse = item.ImpulseForce * (hitPosition - origin).Unit
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
		onPropHit(item, by, propLike, hitPart, hitPosition, origin)
		return "Prop"
	else
		local char = GetMapObjectWithTag(hitPart, "Character")
		local victim = if char and char:IsA("Model") then round:GetParticipant(char) else nil
		if victim then
			onParticipantHit(item, by, victim, hitPart, hitPosition, origin, impulse, originalItem)
			return "Participant"
		end
	end

	local params: Types.DamageParams = {
		Amount = getItemDamage(item, hitPart, origin),
		Source = (if item.Kind == "ExplosionParams" then "Explode" else item) :: Types.DamageSource,

		Attacker = by,

		HitPosition = hitPosition,
		Direction = (hitPosition - origin).Unit,
		Origin = origin,
		HitPart = hitPart,
	}

	local data = if item.Kind == "Item" then item else item.Definition

	if data.BeforeHitAnything then
		if not (data.BeforeHitAnything :: Types.BeforeHitAnything)(item :: Types.Item, params, round) then
			return
		end
	end

	if normal then
		if relativeHitCFrame and relativeHitCFrame.Position.Magnitude <= hitPart.ExtentsSize.Magnitude * 1.1 and item.Kind == "Item" and item.Projectile then
			ReplicatedStorage.Remotes.ServerClient.MakeBulletHole:FireAllClients(hitPart, relativeHitCFrame, normal)
		end
	end

	return "Part"
end

function module.CreateExplosion(round: Types.Round, params: Types.ExplosionParams, item: Types.Item?, sound: Sound?): ()
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
				onPropHit(params, params.Attacker, prop, v, v.Position, params.Position)
				continue
			end

			local interactable = round:GetInteractable(propObject)
			if interactable then
				if table.find(hits, interactable) then
					continue
				end
				table.insert(hits, interactable)
				onPropHit(params, params.Attacker, interactable, v, v.Position, params.Position)
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
			onParticipantHit(params, params.Attacker, participant, v, v.Position, params.Position, impulse, item)
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

function module.Fire(by: Types.Participant, request: CombatTypes.Request): CombatTypes.ValidateUsageResult
	local item = by:GetEquippedItem()
	if not item or item.Name ~= request.ItemName then
		return "NotEquipped"
	end

	local validateItemUsageResult = validateItemUsage(by, item, request)
	if validateItemUsageResult ~= "Success" then
		return validateItemUsageResult :: CombatTypes.ValidateUsageResult
	end

	local char = by:GetCharacter()
	if not char then
		return "OriginTooFar"
	end

	local sound = if request.Action == "Primary" then item.PrimarySound else item.AlternateSound
	if sound then
		for _, v in Players:GetPlayers() do
			if v ~= by.Player then
				PlaySound(sound, nil, char.PrimaryPart, nil, v)
			end
		end
	end

	if request.Action == "Primary" and item.Ammo and item.UseAttack then
		item.Ammo -= 1
	end

	local animation = if request.Action == "Primary" then item.PrimaryAnimation else item.AlternateAnimation
	if animation then
		by:TryPlayAnimation(animation, "MeleeAttack")
	end

	if item.IsSingleUse then
		by:RemoveItem(item)
	end

	if request.Action == "Primary" then
		if item.PrimaryFireServer then
			item.PrimaryFireServer(item, by, request.Origin, request.Direction)
		elseif item.UseAttack then
			if not item.IsProjectileSimulated then
				for i, raycast in ipairs(request.Raycasts) do
					if i > (item.ProjectileCount or 1) then
						break
					end

					if item.Projectile then
						BulletTracer(item.Projectile, item.ProjectileSpeed or 100, request.Origin, raycast.Destination, by.Player)
					end

					local validate = validateRaycast(item, by, request.Origin, raycast.Destination, raycast.HitPart, raycast.HitPartCenterPosition)
					if validate ~= "Success" then
						return validate :: CombatTypes.ValidateUsageResult
					end

					if not item.IsSilent then
						applyNearMissSelfDefense(request.Origin, raycast.Destination, by)
					end

					if raycast.HitPart then
						onPartHit(item, by, raycast.HitPart, raycast.Destination, raycast.Normal, request.Origin, raycast.RelativeHitCFrame, item)
					end
				end
			else
				assert(item.Projectile, "Simulated items must define a projectile")

				local projectile = item.Projectile:Clone()
				ForEachPart(projectile, function(part)
					part.Anchored = false
					part.CollisionGroup = "WeaponHitTargets"
				end)

				;(projectile :: Instance).Parent = workspace.Projectiles

				local primaryPart = GetPrimaryPart(projectile)

				primaryPart:SetNetworkOwner(nil)
				by:TryThrowAssembly(projectile, item.ProjectileSpeed or 100, nil, request.Origin, request.Direction)

				if item.FuseTime and item.ExplosionInfo then
					task.wait(item.FuseTime)

					local params = ExplosionParams.new(item.ExplosionInfo, primaryPart.Position, by)

					module.CreateExplosion(by.Round, params, item)

					if item.OnExplode then
						item.OnExplode(params)
					end
				else
					local maxBounces = item.MaxBounces or 1
					local bounces = 0

					local startTime = os.clock()

					ForEachPart(projectile, function(part)
						part.Touched:Connect(function(otherPart)
							if (os.clock() - startTime < 0.5 and char and otherPart:IsDescendantOf(char)) or not PhysicsService:CollisionGroupsAreCollidable(part.CollisionGroup, otherPart.CollisionGroup) then
								return
							end

							bounces += 1

							local projPosition = primaryPart.Position

							local surfacePosition = otherPart:GetClosestPointOnSurface(projPosition)
							local normal = projPosition - surfacePosition

							local result = onPartHit(item, by, otherPart, surfacePosition, normal, request.Origin, nil, item)

							if bounces >= maxBounces or result == "Participant" then
								projectile:Destroy()
							end
						end)
					end)
				end
			end
		end
	else
		if item.AlternateFireServer then
			item.AlternateFireServer(item, by, request.Origin, request.Direction)
		end
	end

	return "Success"
end

return module