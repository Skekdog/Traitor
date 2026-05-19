local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DNATraces = require(ReplicatedStorage.API.DNATraces)
local KillHighlights = require(ReplicatedStorage.API.Item.Behaviour.KillHighlights)
local BlockFriendlyDamage = require(ReplicatedStorage.API.Prop.BlockFriendlyDamage)
local BreakSound = require(ReplicatedStorage.API.Prop.BreakSound)
local IsHostileParticipant = require(ReplicatedStorage.API.Prop.IsHostileParticipant)
local HealthStation = require(script.Parent.HealthStation)
local Types = require(ReplicatedStorage.API.Types)

type DeathStationServer = Types.Prop & {
	Interactable: Types.InteractableDefinition,
	Extras: {
		DeniedSound: Sound?,
		Participant: Types.Participant?,
	}
}

local function OnLoadServer(interactable: Types.Prop): ()
	local deathStation = interactable :: DeathStationServer

	deathStation.Extras.DeniedSound = ReplicatedStorage.Assets.InteractableSounds.Deny:Clone()

	local participant: Types.Participant? = interactable.Extras.Participant
	if participant then
		DNATraces.Add(interactable, participant, nil, Content.fromAssetId(93284379186217), interactable.Model)
	end
end

local highlights: {KillHighlights.ItemKillHighlight} = {
	{
		Title = "A Lesson in Trickery",
		Description = "%s fooled 1 person with a Death Station.",
		Threshold = 1,
		Priority = 2,
	},
	{
		Title = "A Lesson in Trickery",
		Description = "%s fooled %d people with a Death Station.",
		Threshold = 2,
		Priority = 2,
	}
}

local function OnInteractServer(interactable: Types.Prop, participant: Types.Participant): ()
	local deathStation = interactable :: DeathStationServer
	if not IsHostileParticipant(interactable, participant) then
		if not deathStation.Extras.DeniedSound.IsPlaying then
			deathStation.Extras.DeniedSound:Play()
		end
		return
	end

	local params: Types.DamageParams = {
		Amount = math.huge,
		Source = "Poison",
		Attacker = deathStation.Extras.Participant,
		IgnoreKarma = true,
	}

	KillHighlights(table.unpack(highlights))({Name = "DeathStation"}, params, participant)

	participant:TryTakeDamage(params)
end

local function OnLoadClient(interactable: Types.Prop): ()
	interactable.HintTextClient = `Charge: {HealthStation.MAX_CHARGE} / {HealthStation.MAX_CHARGE}`
end

local model = ReplicatedStorage.Assets.InteractableModels.HealthStation:Clone()
model.Name = "DeathStation"
model.Parent = ReplicatedStorage.Assets.InteractableModels

local interactable: Types.InteractableDefinition = {
	Name = "DeathStation",
	DisplayName = "Health Station",

	Model = model,

	InteractionRange = 7.5,
	IsContinuousInteraction = true,

	OnInteractServer = OnInteractServer,
	OnLoadServer = OnLoadServer,

	OnLoadClient = OnLoadClient,

	BeforeTakeDamage = BlockFriendlyDamage,

	OnBreakServer = BreakSound(),
}

return table.freeze(interactable)