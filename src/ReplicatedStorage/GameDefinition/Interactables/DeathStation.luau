local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HealthStation = require(script.Parent.HealthStation)
local Types = require(ReplicatedStorage.RoundRule.Types)

type DeathStationServer = Types.Interactable & {
	Extras: {
		DeniedSound: Sound?,
	}
}

local function OnLoadServer(interactable: DeathStationServer): ()
	local deniedSound = Instance.new("Sound")
	deniedSound.SoundId = "rbxassetid://72729349003330"
	deniedSound.RollOffMinDistance = 5
	deniedSound.RollOffMaxDistance = 15
	deniedSound.Parent = interactable.Object

	interactable.Extras.DeniedSound = deniedSound
end

local function OnInteractServer(interactable: DeathStationServer, participant: Types.Participant): ()
	local role = participant:GetRole()
	if role and role.Definition.IsBadGuys then
		if not interactable.Extras.DeniedSound.IsPlaying then
			interactable.Extras.DeniedSound:Play()
		end
		return
	end

	participant:TryTakeDamage({
		Amount = math.huge,
		Source = "Poison",
		Attacker = participant,
		IgnoreKarma = true,
	})
end

local function OnLoadClient(interactable: Types.Interactable): ()
	interactable.HintTextClient = `Charge: {HealthStation.MAX_CHARGE} / {HealthStation.MAX_CHARGE}`
end

local interactable: Types.InteractableDefinition = {
	Name = "DeathStation",
	DisplayName = "Health Station",

	Model = ReplicatedStorage.InteractableModels.HealthStation,

	InteractionRange = 7.5,
	IsContinuousInteraction = true,

	OnInteractServer = OnInteractServer,
	OnLoadServer = OnLoadServer,

	OnLoadClient = OnLoadClient,
}

return interactable