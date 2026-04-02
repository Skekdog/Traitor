local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BlockFriendlyDamage = require(ReplicatedStorage.API.Prop.BlockFriendlyDamage)
local IsHostileParticipant = require(ReplicatedStorage.API.Prop.IsHostileParticipant)
local DNAScanner = require(ReplicatedStorage.Shared.GameDefinition.Items.Custom.DNAScanner)
local HealthStation = require(script.Parent.HealthStation)
local Types = require(ReplicatedStorage.Shared.RoundRule.Types)

type DeathStationServer = Types.Prop & {
	Interactable: Types.InteractableDefinition,
	Extras: {
		DeniedSound: Sound?,
		Participant: Types.Participant?,
	}
}

local function OnLoadServer(interactable: Types.Prop): ()
	local deathStation = interactable :: DeathStationServer

	local deniedSound = Instance.new("Sound")
	deniedSound.SoundId = "rbxassetid://72729349003330"
	deniedSound.RollOffMinDistance = 5
	deniedSound.RollOffMaxDistance = 15
	deniedSound.Parent = interactable.Model

	deathStation.Extras.DeniedSound = deniedSound

	local participant: Types.Participant? = interactable.Extras.Participant
	if participant then
		DNAScanner.AddDNATrace(interactable, participant, nil, Content.fromAssetId(93284379186217), interactable.Model)
	end
end

local function OnInteractServer(interactable: Types.Prop, participant: Types.Participant): ()
	local deathStation = interactable :: DeathStationServer
	if not IsHostileParticipant(interactable, participant) then
		if not deathStation.Extras.DeniedSound.IsPlaying then
			deathStation.Extras.DeniedSound:Play()
		end
		return
	end

	participant:TryTakeDamage({
		Amount = math.huge,
		Source = "Poison",
		Attacker = deathStation.Extras.Participant,
		IgnoreKarma = true,
	})
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
}

return table.freeze(interactable)