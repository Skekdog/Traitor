local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BulletTracer = require(ReplicatedStorage.BulletTracer)
local CombatTypes = require(ReplicatedStorage.CombatTypes)
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

local function getItemDamage(definition: Types.AnyItemDefinition, hitPart: BasePart): number
	assert(definition.Kind ~= "Item", "Item has no damage")

	if typeof(definition.Damage) == "number" then
		return definition.Damage
	end

	local hitArea: "Body" | "Head" | "Limb" = "Limb"
	if isOf(hitPart, "Head") then
		hitArea = "Head"
	elseif isOf(hitPart, "Torso", true) or isOf(hitPart, "HumanoidRootPart") then
		hitArea = "Body"
	else
		hitArea = "Limb"
	end

	return definition.Damage[hitArea]
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
local function validateRaycast(by: Types.Participant, origin: Vector3, destination: Vector3, target: BasePart?, targetCenterPosition: Vector3?): CombatTypes.ValidateRaycastResult
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

local function validateItemUsage(by: Types.Participant, item: Types.AnyItem): CombatTypes.ValidateItemUsageResult
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

local function onParticipantHit(item: Types.AnyItem, by: Types.Participant, victim: Types.Participant, hitPart: BasePart, hitPosition: Vector3): ()
	local definition = item.Definition
	if definition.Kind == "Item" then
		return
	end

	victim:TryTakeDamage({
		Amount = getItemDamage(definition, hitPart),
		Source = if definition.Kind == "Gun" then "Shot" elseif definition.Kind == "Melee" then definition.DamageKind else "Other",

		IsHeadshot = hitPart.Name == "Head",
		Attacker = by,
	})
end

local function onWindowHit(item: Types.AnyItem, by: Types.Participant, hitPart: BasePart, hitPosition: Vector3): ()
	ShatterGlass(hitPart)
end

local function onPropHit(item: Types.AnyItem, by: Types.Participant, prop: Types.Prop, hitPart: BasePart, hitPosition: Vector3): ()
	prop:TryTakeDamage({
		Amount = getItemDamage(item.Definition, hitPart),
		Source = if item.Definition.Kind == "Gun" then "Shot" elseif item.Definition.Kind == "Melee" then item.Definition.DamageKind else "Other",

		Attacker = by,
	})
end

local function onPartHit(item: Types.AnyItem, by: Types.Participant, hitPart: BasePart, hitPosition: Vector3): ()
	local round = by.Round
	local map = round:GetMap()

	local victim = tryGetParticipantFromPart(by.Round, hitPart)
	local prop = round:GetProp(hitPart)
	if victim then
		onParticipantHit(item, by, victim, hitPart, hitPosition)
	elseif hitPart:IsDescendantOf(map.Windows) then
		onWindowHit(item, by, hitPart, hitPosition)
	elseif prop then
		onPropHit(item, by, prop, hitPart, hitPosition)
	end
end

function module.PrimaryFire(by: Types.Participant, request: CombatTypes.PrimaryFireRequest): CombatTypes.ValidateItemUsageResult
	local item = by:GetEquippedItem()
	if not item or item.Definition.Name ~= request.ItemName then
		return "NotEquipped"
	end

	local validateItemUsageResult = validateItemUsage(by, item)
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
	end

	for i, v in ipairs(request.Shots) do
		if i > (if item.Kind == "Gun" then item.Definition.BulletsPerShot or 1 else 1) then
			break
		end

		if definition.Kind == "Gun" and definition.Projectile then
			BulletTracer(definition.Projectile, definition.ProjectileSpeed or 100, request.Origin, v.Destination)
		end

		local validateRaycastResult = validateRaycast(by, request.Origin, v.Destination, v.HitPart, v.HitPartCenterPosition)
		if validateRaycastResult ~= "Success" then
			return validateRaycastResult :: CombatTypes.ValidateRaycastResult
		end

		if v.HitPart then
			onPartHit(item, by, v.HitPart, v.Destination)
		end
	end

	return "Success"
end

return module