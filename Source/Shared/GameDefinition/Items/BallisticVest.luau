local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Participant = require(ReplicatedStorage.Shared.RoundRule.Participant)
local Types = require(ReplicatedStorage.Shared.RoundRule.Types)

local module = {}

type Participant = Types.Participant & {
	Extras: {
		BallisticVest: number?,
		[any]: nil,
	}
}

local function isTorso(part: BasePart): boolean
	return part.Name == "HumanoidRootPart" or part.Name:match("Torso") ~= nil
end

local function isGunSource(source: Types.DamageSource): boolean
	return source == "Shot" or (typeof(source) == "table" and source.Kind == "Gun")
end

local originalTryTakeDamage = Participant.TryTakeDamage

local function patchedTryTakeDamage(participant: Participant, params: Types.DamageParams, deferDeath: boolean?): boolean
	if isGunSource(params.Source) and ((participant.Extras.BallisticVest or 0) > 0) and params.HitPart and isTorso(params.HitPart) then
		local reduction = math.clamp(params.Amount, 0, participant.Extras.BallisticVest)
		participant.Extras.BallisticVest -= reduction
		params.Amount -= reduction
	end

	return originalTryTakeDamage(participant, params, deferDeath)
end

local item: Types.ItemDefinition = {
	Kind = "Item" :: "Item",
    Name = "Ballistic Vest",
    Description = "Absorbs a limited amount of damage to the torso. Not visible to others.",
    Icon = "rbxassetid://395920626",

    CreditCost = 1,
    MaxStock = 1,

    OnEquipServer = function(item, participant: Types.Participant)
        participant.Extras.BallisticVest = 60
		participant.TryTakeDamage = patchedTryTakeDamage
    end,
}

module.Item = item

return module