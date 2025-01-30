local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.RoundRule.Types)
local module = {}

local MAX_SHOOTER_DISTANCE = 15
local MAX_TARGET_DISTANCE = 10

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
local function validateRaycast(by: Types.Participant, origin: Vector3, destination: Vector3, target: BasePart?): ValidateRaycastResult
	local char = by:GetCharacter()
	if not char or (char:GetPivot().Position - origin).Magnitude > MAX_SHOOTER_DISTANCE then
		return "ShooterTooFar"
	end

	if target and (target.Position - destination).Magnitude > MAX_TARGET_DISTANCE then
		return "TargetTooFar"
	end

	if target then
		local params = RaycastParams.new()
		params.FilterDescendantsInstances = {by.Round:GetMap().StaticMap}
		params.FilterType = Enum.RaycastFilterType.Include
		params.RespectCanCollide = true
		params.IgnoreWater = true

		local result = workspace:Raycast(origin, destination - origin, params)
		if result and result.Instance ~= target then
			return "StaticObscured"
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

function module.PrimaryFire(by: Types.Participant, item: Types.AnyItem, origin: Vector3, destination: Vector3, hitPart: BasePart?): ValidateItemUsageResult
	local validateItemUsageResult = validateItemUsage(by, item)
	if validateItemUsageResult ~= "Success" then
		return validateItemUsageResult :: ValidateItemUsageResult
	end

	local validateRaycastResult = validateRaycast(by, origin, destination, hitPart)
	if validateRaycastResult ~= "Success" then
		return validateRaycastResult :: ValidateRaycastResult
	end

	local definition = item.Definition

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