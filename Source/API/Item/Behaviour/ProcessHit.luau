local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GetMapObject = require(ReplicatedStorage.API.GetMapObject)
local GetMaterial = require(ReplicatedStorage.API.GetMaterial)
local Impulse = require(ReplicatedStorage.API.Impulse)
local PlaySound = require(ReplicatedStorage.API.PlaySound)
local Types = require(ReplicatedStorage.API.Types)
local HitSounds = require(ReplicatedStorage.Shared.Combat.HitSounds)
local Replication = require(ReplicatedStorage.Shared.RoundRule.Replication)

local ProcessHit = {}

local function isOf(part: BasePart, name: string, match: boolean?): boolean?
	local accessoryWeld = part:FindFirstChild("AccessoryWeld") :: Weld
	if accessoryWeld and accessoryWeld.Part1 and accessoryWeld.Part1.Name == name then
		if accessoryWeld.Part1.Name == name or (match and (accessoryWeld.Part1.Name:match(name) ~= nil)) then
			return true
		end
	end
	return (part.Name == name) or (part:FindFirstAncestor(name) ~= nil) or (match and (part.Name:match(name) ~= nil))
end

function ProcessHit.GetBodyPart(part: BasePart): "Body" | "Head" | "Limb"
	local hitArea: "Body" | "Head" | "Limb" = "Limb"
	if isOf(part, "Head") then
		hitArea = "Head"
	elseif isOf(part, "Torso", true) or isOf(part, "HumanoidRootPart") then
		hitArea = "Body"
	end
	return hitArea
end

function ProcessHit.GetItemDamage(item: Types.Item | Types.ExplosionParams, hitPart: BasePart, origin: Vector3): number
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

function ProcessHit.Part(item: Types.Item | Types.ExplosionParams, by: Types.Participant, hitPart: BasePart, hitPosition: Vector3, normal: Vector3?, origin: Vector3, relativeHitCFrame: CFrame?, projectile: Types.MapObject?, timeOrigin: number?): "Part" | "Prop" | "Participant"?
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
				local sound: PlaySound.SoundId | {PlaySound.SoundId}
				if item.Kind == "Item" and item.HitSound then
					sound = item.HitSound
				end

				if not sound then
					sound = HitSounds[GetMaterial(hitPart)] or HitSounds.Default
				end

				PlaySound(sound, hitPosition, nil, {
					RollOffMinDistance = 0,
					RollOffMaxDistance = 20,
				}, v)
			end
		end
	end

	local params: Types.DamageParams = {
		Amount = ProcessHit.GetItemDamage(item, hitPart, origin),
		Source = (if item.Kind == "ExplosionParams" then "Explode" else item) :: Types.DamageSource,

		Attacker = by,

		TimeOrigin = timeOrigin,
		HitPosition = hitPosition,
		Direction = (hitPosition - origin).Unit,
		Origin = origin,
		HitPart = hitPart,

		Projectile = projectile,
	}

	local data = if item.Kind == "Item" then item else item.Definition

	if data.BeforeHitAnything then
		if not (data.BeforeHitAnything :: Types.BeforeHitAnything)(item :: Types.Item, params, round) then
			return
		end
	end

	local MapObject = GetMapObject(hitPart, "Prop")
	local prop = round:GetProp(MapObject or hitPart)

	if prop then
		ProcessHit.Prop(item, by, prop, hitPart, hitPosition, origin, projectile)
		return "Prop"
	else
		local char = GetMapObject(hitPart, "Character")
		local victim = if char and char:IsA("Model") then round:GetParticipant(char) else nil
		if victim then
			ProcessHit.Participant(item, by, victim, hitPart, hitPosition, origin, impulse, projectile)
			return "Participant"
		end
	end

	if normal then
		if relativeHitCFrame and relativeHitCFrame.Position.Magnitude <= hitPart.ExtentsSize.Magnitude * 1.1 and item.Kind == "Item" and item.Projectile then
			ReplicatedStorage.Remotes.ServerClient.MakeBulletHole:FireAllClients(hitPart, relativeHitCFrame, normal)
		end
	end

	return "Part"
end

function ProcessHit.Participant(item: Types.Item | Types.ExplosionParams, by: Types.Participant?, victim: Types.Participant, hitPart: BasePart, hitPosition: Vector3, origin: Vector3, impulse: Vector3?, projectile: Types.MapObject?, timeOrigin: number?): ()
	if item.Kind ~= "ExplosionParams" then
		assert(by, "by must not be nil")
	end

	if victim.Round:IsPreGame() then
		return
	end

	local data = if item.Kind == "ExplosionParams" then item.Definition else item

	local damage = ProcessHit.GetItemDamage(item, hitPart, origin)

	local params: Types.DamageParams = {
		Amount = damage,
		Source = (if item.Kind == "ExplosionParams" then "Explode" else item) :: Types.DamageSource,
		IsHeadshot = item.Kind == "Item" and item.CanHeadshot and isOf(hitPart, "Head"),
		Attacker = by,

		TimeOrigin = timeOrigin,
		HitPosition = hitPosition,
		Origin = origin,
		Direction = (hitPosition - origin).Unit,
		HitPart = hitPart,

		Projectile = projectile,
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

	local originalItem = if item.Kind == "Item" then item else item.SourceItem
	if originalItem and originalItem.OnHitClient then
		Replication.RunOnHitClient(originalItem, victim, hitPart)
	end

	local willDie = params.Amount >= victim:GetHealth()
	if willDie then
		victim.Extras.CombatImpulse = impulse
	end

	victim:TryTakeDamage(params, item.Kind == "ExplosionParams")
end

function ProcessHit.Prop(item: Types.Item | Types.ExplosionParams, by: Types.Participant?, prop: Types.Prop, hitPart: BasePart, hitPosition: Vector3, origin: Vector3, projectile: Types.MapObject?, timeOrigin: number?): ()
	if item.Kind ~= "ExplosionParams" then
		assert(by, "by must not be nil")
	end

	local damage = ProcessHit.GetItemDamage(item, hitPart, origin)

	local params = {
		Amount = damage,
		Source = (if item.Kind == "ExplosionParams" then "Explode" else item) :: Types.DamageSource,

		Attacker = by,

		TimeOrigin = timeOrigin,
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

	prop:TryTakeDamage(params)
end

return table.freeze(ProcessHit)