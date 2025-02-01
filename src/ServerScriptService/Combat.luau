local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BulletTracer = require(ReplicatedStorage.BulletTracer)
local Types = require(ReplicatedStorage.RoundRule.Types)
local module = {}

local MAX_SHOOTER_DISTANCE = 15
local MAX_TARGET_DISTANCE = 10
local STATIC_OBSCURE_DISTANCE = 0.05

export type ValidateRaycastResult = "TargetTooFar" | "ShooterTooFar" | "StaticObscured" | "Success"

export type ValidateItemUsageResult = "Dead" | "NotEnoughAmmo" | "FiringTooFast" | "NotEquipped"
										| "Success" | "UnknownItem" | "NotInRound" | ValidateRaycastResult
										

local function getItemDamage(definition: Types.AnyItemDefinition, hitPart: BasePart): number
	assert(definition.Kind ~= "Item", "Item has no damage")

	if typeof(definition.Damage) == "number" then
		return definition.Damage
	end

	local hitArea: "Body" | "Head" | "Limb" = "Limb"
	if hitPart.Name == "Head" then
		hitArea = "Head"
	elseif hitPart.Name:match("Torso") or hitPart.Name == "HumanoidRootPart" then
		hitArea = "Body"
	elseif hitPart.Name:match("Leg") or hitPart.Name:match("Arm") or hitPart.Name:match("Foot") or hitPart.Name:match("Hand") then
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
local function validateRaycast(by: Types.Participant, origin: Vector3, destination: Vector3, target: BasePart?, targetCenterPosition: Vector3?): ValidateRaycastResult
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
		params.RespectCanCollide = true
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

local function validateItemUsage(by: Types.Participant, item: Types.AnyItem): ValidateItemUsageResult
	if by:GetHealth() <= 0 then
		return "Dead"
	end

	if by:GetEquippedItem() ~= item then
		return "NotEquipped"
	end

	if item.Kind == "Gun" and item.Ammo <= 0 then
		return "NotEnoughAmmo"
	end

	return "Success"
end

function module.PrimaryFire(by: Types.Participant, item: Types.AnyItem, origin: Vector3, destination: Vector3, hitPart: BasePart?, hitPartCenterPosition: Vector3?): ValidateItemUsageResult
	local validateItemUsageResult = validateItemUsage(by, item)
	if validateItemUsageResult ~= "Success" then
		return validateItemUsageResult :: ValidateItemUsageResult
	end

	local validateRaycastResult = validateRaycast(by, origin, destination, hitPart, hitPartCenterPosition)
	if validateRaycastResult ~= "Success" then
		return validateRaycastResult :: ValidateRaycastResult
	end

	local definition = item.Definition

	if definition.Kind == "Gun" and definition.Projectile then
		BulletTracer(definition.Projectile, definition.ProjectileSpeed or 100, origin, destination)
	end

	if hitPart then
		local victim = tryGetParticipantFromPart(by.Round, hitPart)
		if victim and definition.Kind ~= "Item" then
			victim:TryTakeDamage({
				Amount = getItemDamage(definition, hitPart),
				Source = if definition.Kind == "Gun" then "Shot" elseif definition.Kind == "Melee" then definition.DamageKind else "Other",

				IsHeadshot = hitPart.Name == "Head",
				Attacker = by,
			})
		end
	end

	return "Success"
end

return module