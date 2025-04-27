local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Types = require(ReplicatedStorage.RoundRule.Types)

local MAX_CHARGE = 200
local HEAL_INTERVAL = 0.5
local HEAL_AMOUNT = 1
local RECHARGE_INTERVAL = 2.5
local RECHARGE_AMOUNT = 1

type HealthStationServer = Types.Interactable & {
	Extras: {
		Charge: number?,
		HealQueue: {Types.Participant}?,
		HealSound: Sound?,
	}
}

local stations: {HealthStationServer} = {}

local function setCharge(interactable: HealthStationServer, charge: number): ()
	interactable.Extras.Charge = math.clamp(charge, 0, MAX_CHARGE)
	interactable.Object:SetAttribute("Charge", interactable.Extras.Charge)
end

local function OnInteractServer(interactable: HealthStationServer, participant: Types.Participant): ()
	local charge = interactable.Extras.Charge or MAX_CHARGE
	local humanoid = participant:GetHumanoid()
	if not humanoid or charge <= 0 or participant:GetHealth() >= humanoid.MaxHealth then
		return
	end

	table.insert(interactable.Extras.HealQueue, participant)
end

local function OnLoadServer(interactable: HealthStationServer): ()
	setCharge(interactable, MAX_CHARGE)
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
	setCharge(station, station.Extras.Charge - HEAL_AMOUNT)

	if not station.Extras.HealSound.IsPlaying then
		station.Extras.HealSound:Play()
	end
end

local lastRecharge = 0
local lastHeal = 0
RunService.Heartbeat:Connect(function()
	local shouldRecharge = tick() - lastRecharge > RECHARGE_INTERVAL
	local shouldHeal = tick() - lastHeal > HEAL_INTERVAL

	for _, station in stations do
		if shouldRecharge then
			setCharge(station, station.Extras.Charge + RECHARGE_AMOUNT)
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

local function updateCharge(interactable: Types.Interactable): ()
	local charge = interactable.Object:GetAttribute("Charge") :: number?
	interactable.HintTextClient = `Charge: {charge} / {MAX_CHARGE}`
end

local function OnLoadClient(interactable: Types.Interactable): ()
	interactable.Object:GetAttributeChangedSignal("Charge"):Connect(function()
		updateCharge(interactable)
	end)
	updateCharge(interactable)
end

local interactable: Types.InteractableDefinition = {
	Name = "HealthStation",
	DisplayName = "Health Station",

	Model = ReplicatedStorage.InteractableModels.HealthStation,

	InteractionRange = 7.5,
	IsContinuousInteraction = true,

	OnInteractServer = OnInteractServer,
	OnLoadServer = OnLoadServer,

	OnLoadClient = OnLoadClient,
}

return interactable