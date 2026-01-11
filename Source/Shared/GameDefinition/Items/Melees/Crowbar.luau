local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Impulse = require(ReplicatedStorage.API.Impulse)
local ItemKillHighlights = require(ReplicatedStorage.API.ItemPresets.ItemKillHighlights)
local Melee = require(ReplicatedStorage.API.ItemPresets.Melee)
local Types = require(ReplicatedStorage.Shared.RoundRule.Types)

local module = {}

local MAX_DISTANCE = 7
local PUSH_FORCE = 75
local RESPONSIBLE_DURATION = 5

local function raycast(head: BasePart, direction: Vector3): RaycastResult?
	local params = RaycastParams.new()
	params.FilterDescendantsInstances = {head.Parent :: Model}
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.IgnoreWater = true
	params.CollisionGroup = "WeaponHitTargets"

	return workspace:Raycast(head.Position, direction * MAX_DISTANCE, params)
end

function module.Push(item: Types.Item, participant: Types.Participant, origin: Vector3, direction: Vector3): ()
	local char = participant:GetCharacter()
	if not char then
		return
	end

	local head = char:FindFirstChild("Head")
	if not head or not head:IsA("BasePart") then
		return
	end

	local raycastResult = raycast(head, direction)
	if not raycastResult then
		return
	end

	local hitPart = raycastResult.Instance :: BasePart
	local model = hitPart:FindFirstAncestorOfClass("Model")

	if not model then
		return
	end

	local hitParticipant = participant.Round:GetParticipant(model.Name)
	if not hitParticipant then
		return
	end

	hitParticipant:SetLastDamagedBy(participant, RESPONSIBLE_DURATION)
	if not participant:HasSelfDefenseAgainstParticipant(hitParticipant) then
		hitParticipant:AddSelfDefenseEntry({
			Against = participant,
			Duration = RESPONSIBLE_DURATION,
		})
	end

	Impulse.ApplyImpulse(hitPart, direction * PUSH_FORCE * hitPart.AssemblyMass, false, nil, participant)
end

local Crowbar = Melee({
    Name = "Crowbar",
	Description = "Hello Gordon",
	IconContent = Content.none,

    ItemGroup = {
		PreferredSlot = 1,
	},
    DropDisabled = true,

    DamageKind = "Bludgeon" :: "Bludgeon",

	ImpulseForce = 5,

    Model = ReplicatedStorage.Assets.ItemModels.Crowbar,
    HoldAnimation = Content.fromAssetId(10247423634),
    PrimaryAnimation = Content.fromAssetId(13269497293),

    MaxDistance = 7,
    Damage = 20,
    PrimaryInterval = 0.3,
	AlternateInterval = 0.3,
    PrimarySound = ReplicatedStorage.Assets.ItemSounds.Fired.Crowbar,
	AlternateSound = ReplicatedStorage.Assets.ItemSounds.Fired.Crowbar,

	BeforeHitParticipant = ItemKillHighlights({
		Title = "Thunk Thunk Thunk",
		Description = "%s has a mean swing with the crowbar, as %d victims found out.",
		Priority = 2,
		Threshold = 2,
	}, {
		Title = "Freeman",
		Description = "%s covered their crowbar in the brains of no less than %d people.",
		Priority = 4,
		Threshold = 4,
	}),

    AlternateFireServer = module.Push,
})

module.Item = Crowbar

return module