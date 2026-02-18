local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BehaviourTypes = require(ReplicatedStorage.API.Item.Behaviour.BehaviourTypes)
local ItemKillHighlights = require(ReplicatedStorage.API.Item.Behaviour.KillHighlights)
local Melee = require(ReplicatedStorage.API.Item.Presets.Melee)
local Types = require(ReplicatedStorage.Shared.RoundRule.Types)

local module = {}

local PUSH_FORCE = 10
local RESPONSIBLE_DURATION = 5

function module.AlternateFireClient(item: Types.Item, origin: Vector3, direction: Vector3): boolean | string | {string}
	local Client = require(ReplicatedStorage.API.Item.Behaviour.Client)

	local result = Client.PrimaryFire(item, origin, direction, true)
	if result ~= true then
		return result
	end

	local data = item:GetServerData("Primary") :: BehaviourTypes.Request
	if not data then
		return false
	end

	item:SetServerData("Primary", nil)

	Client.Recoil(item)

	if not data[1] or not data[1].Hit then
		return false
	end

	item:SetServerData("Alternate", data)

	return true
end

function module.AlternateFireServer(item: Types.Item, origin: Vector3, direction: Vector3, participant: Types.Participant, data: unknown): string?
	local GetParticipant = require(ReplicatedStorage.API.GetParticipant)
	local Impulse = require(ReplicatedStorage.API.Impulse)

	if not BehaviourTypes.IsRequest(data) then
		return "InvalidRequest"
	end

	local request = data :: BehaviourTypes.Request
	if not request then
		return "InvalidRequest"
	end

	local hitscan = request[1]
	if not hitscan or not hitscan.Hit then
		return "InvalidRequest"
	end

	local part = hitscan.Hit.Part
	local force = direction * PUSH_FORCE

	local hitParticipant = GetParticipant(part)
	if hitParticipant then
		force *= 6
	end

	if Impulse.CanImpulse(part) then
		Impulse.ApplyImpulse(part, force, true, hitscan.Position, participant)
	end

	if not hitParticipant then
		return nil
	end

	hitParticipant:SetLastDamagedBy(participant, RESPONSIBLE_DURATION)
	if not participant:HasSelfDefenseAgainstParticipant(hitParticipant) then
		hitParticipant:AddSelfDefenseEntry({
			Against = participant,
			Duration = RESPONSIBLE_DURATION,
		})
	end

	return nil
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
	AlternateAnimation = Content.fromAssetId(13269497293),

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

    AlternateFireServer = module.AlternateFireServer,
	AlternateFireClient = module.AlternateFireClient,
})

module.Item = Crowbar

return module