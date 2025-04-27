local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Types = require(ReplicatedStorage.RoundRule.Types)

local MAX_CHARGE = 200
local HEAL_INTERVAL = 0.5
local HEAL_AMOUNT = 1
local RECHARGE_RATE = 1

type HealthStationServer = Types.Interactable & {
	Extras: {
		Charge: number?,
		HealQueue: {Types.Participant}?,
		HealSound: Sound?,
	}
}

local stations: {HealthStationServer} = {}

local function OnInteractServer(interactable: HealthStationServer, participant: Types.Participant): ()
	local charge = interactable.Extras.Charge or MAX_CHARGE
	local humanoid = participant:GetHumanoid()
	if not humanoid or charge <= 0 or participant:GetHealth() >= humanoid.MaxHealth then
		return
	end

	table.insert(interactable.Extras.HealQueue, participant)
end

local function OnLoadServer(interactable: HealthStationServer): ()
	interactable.Extras.Charge = MAX_CHARGE
	interactable.Extras.HealQueue = {}
	table.insert(stations, interactable)

	local healSound = Instance.new("Sound")
	healSound.SoundId = "rbxassetid://4720447470"
	healSound.RollOffMinDistance = 5
	healSound.RollOffMaxDistance = 15
	healSound.PlaybackRegionsEnabled = true
	healSound.PlaybackRegion = NumberRange.new(0.2, 1.19)
	healSound.Parent = interactable.Object

	interactable.Extras.HealSound = healSound
end

local function heal(station: HealthStationServer, participant: Types.Participant): ()
	participant.Extras.HealthStationLastHealedAt = tick()
	participant:SetHealth(participant:GetHealth() + HEAL_AMOUNT)
	station.Extras.Charge = math.clamp(station.Extras.Charge - HEAL_AMOUNT, 0, MAX_CHARGE)

	if not station.Extras.HealSound.IsPlaying then
		station.Extras.HealSound:Play()
	end
end

local lastRecharge = 0
local lastHeal = 0
RunService.Heartbeat:Connect(function()
	local shouldRecharge = tick() - lastRecharge > RECHARGE_RATE
	local shouldHeal = tick() - lastHeal > HEAL_INTERVAL
	
	for _, station in stations do
		if shouldRecharge then
			station.Extras.Charge = math.clamp(station.Extras.Charge + RECHARGE_RATE, 0, MAX_CHARGE) -- clamp instead of min because then we can have negative recharge if we really want to
		end

		if shouldHeal then
			local healQueue: {Types.Participant} = station.Extras.HealQueue
			local chosenParticipant: Types.Participant?, lastHealedAt: number = nil, math.huge
			for _, participant in healQueue do
				if not participant.Extras.HealthStationLastHealedAt or participant.Extras.HealthStationLastHealedAt <= lastHealedAt then
					chosenParticipant = participant
					lastHealedAt = participant.Extras.HealthStationLastHealedAt or 0
				end
			end

			if chosenParticipant then
				heal(station, chosenParticipant)
			end
		end

		station.Extras.HealQueue = {}
	end

	if shouldRecharge then
		lastRecharge = tick()
	end

	if shouldHeal then
		lastHeal = tick()
	end
end)

local interactable: Types.InteractableDefinition = {
	Name = "HealthStation",
	DisplayName = "Health Station",

	Model = ReplicatedStorage.InteractableModels.HealthStation,

	InteractionRange = 7.5,
	IsContinuousInteraction = true,

	OnInteractServer = OnInteractServer,
	OnLoadServer = OnLoadServer,
}

return interactable