local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HealthStation = require(script.Parent.HealthStation)
local Types = require(ReplicatedStorage.Shared.RoundRule.Types)

type DeathStationServer = Types.Interactable & {
	Extras: {
		DeniedSound: Sound?,
		Owner: Types.Participant?,
	}
}

local function OnLoadServer(interactable: DeathStationServer): ()
	local deniedSound = Instance.new("Sound")
	deniedSound.SoundId = "rbxassetid://72729349003330"
	deniedSound.RollOffMinDistance = 5
	deniedSound.RollOffMaxDistance = 15
	deniedSound.Parent = interactable.Model

	interactable.Extras.DeniedSound = deniedSound
end

local function OnInteractServer(interactable: DeathStationServer, participant: Types.Participant): ()
	if participant:GetRole().Definition.IsEvil then
		if not interactable.Extras.DeniedSound.IsPlaying then
			interactable.Extras.DeniedSound:Play()
		end
		return
	end

	participant:TryTakeDamage({
		Amount = math.huge,
		Source = "Poison",
		Attacker = interactable.Extras.Owner,
		IgnoreKarma = true,
	})
end

local function OnLoadClient(interactable: Types.Interactable): ()
	interactable.HintTextClient = `Charge: {HealthStation.MAX_CHARGE} / {HealthStation.MAX_CHARGE}`
end

local function BeforeTakeDamage(interactable: DeathStationServer, params: Types.DamageParams?): boolean
	if not params then
		return false
	end

	local attacker = params.Attacker
	if not attacker then
		return false
	end

	return not attacker:GetRole().Definition.IsEvil
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

	BeforeTakeDamage = BeforeTakeDamage,
}

return interactable