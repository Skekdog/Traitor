local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DamageSource = require(ReplicatedStorage.API.DamageSource)
local ProcessHit = require(ReplicatedStorage.API.Item.Behaviour.ProcessHit)
local Custom = require(ReplicatedStorage.API.Item.Presets.Custom)
local GameHooks = require(ReplicatedStorage.API.GameHooks)
local Types = require(ReplicatedStorage.Shared.RoundRule.Types)

local module = {}

type Participant = Types.Participant & {
	Extras: {
		BallisticVest: number?,
		[any]: nil,
	}
}

GameHooks.BeforeDamageParticipant["BallisticVest"] = function(round: Types.Round, participant: Participant, params: Types.DamageParams)
	if not params.HitPart or not DamageSource.IsFirearm(params.Source) or ((participant.Extras.BallisticVest or 0) <= 0) or ProcessHit.GetBodyPart(params.HitPart) ~= "Body" then
		return
	end

	local reduction = math.clamp(params.Amount, 0, participant.Extras.BallisticVest)
	participant.Extras.BallisticVest -= reduction
	params.Amount -= reduction
end

local item = Custom({
    Name = "Ballistic Vest",
    Description = "Absorbs a limited amount of damage to the torso. Not visible to others.",
    IconContent = Content.fromAssetId(395920626),

	CorpseIconDescription = "They were wearing %s.",

    Cost = 1,
    MaxStock = 1,

    OnEquipServer = function(item, participant: Types.Participant)
        participant.Extras.BallisticVest = 60
    end,
})

module.Item = item

return table.freeze(module)