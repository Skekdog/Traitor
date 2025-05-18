local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local DNAScanner = require(ReplicatedStorage.Shared.GameDefinition.Items.DNAScanner)
local Types = require(ReplicatedStorage.Shared.RoundRule.Types)

local module = {}
module.MAX_CHARGE = 200
module.HEAL_INTERVAL = 0.5
module.HEAL_AMOUNT = 1
module.RECHARGE_INTERVAL = 2.5
module.RECHARGE_AMOUNT = 1

type HealthStationServer = Types.Interactable & {
	Extras: {
		Charge: number?,
		HealQueue: {Types.Participant}?,
		HealSound: Sound?,
		NoChargeSound: Sound?,
		[any]: nil,
	}
}

local stations: {HealthStationServer} = {}

local function setCharge(interactable: HealthStationServer, charge: number): ()
	interactable.Extras.Charge = math.clamp(charge, 0, module.MAX_CHARGE)
	interactable.Object:SetAttribute("Charge", interactable.Extras.Charge)
end

local function OnInteractServer(interactable: HealthStationServer, participant: Types.Participant): ()
	local charge = interactable.Extras.Charge or module.MAX_CHARGE
	local humanoid = participant:GetHumanoid()
	if not humanoid or participant:GetHealth() >= humanoid.MaxHealth then
		return
	end

	if charge < module.HEAL_AMOUNT then
		if not interactable.Extras.NoChargeSound.IsPlaying then
			interactable.Extras.NoChargeSound:Play()
		end
		return
	end

	table.insert(interactable.Extras.HealQueue, participant)
end

local function OnLoadServer(interactable: HealthStationServer): ()
	setCharge(interactable, module.MAX_CHARGE)
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

	local noChargeSound = Instance.new("Sound")
	noChargeSound.SoundId = "rbxassetid://72729349003330"
	noChargeSound.RollOffMinDistance = 5
	noChargeSound.RollOffMaxDistance = 15
	noChargeSound.Parent = interactable.Object

	interactable.Extras.NoChargeSound = noChargeSound
end

local function heal(station: HealthStationServer, participant: Types.Participant): ()
	participant.Extras.HealthStationLastHealedAt = tick()
	participant:SetHealth(participant:GetHealth() + module.HEAL_AMOUNT)
	setCharge(station, station.Extras.Charge - module.HEAL_AMOUNT)

	if not station.Extras.HealSound.IsPlaying then
		station.Extras.HealSound:Play()
	end

	DNAScanner.AddDNATrace(station, participant, nil, "rbxassetid://93284379186217", station.Object)
end

local lastRecharge = 0
local lastHeal = 0
RunService.Heartbeat:Connect(function()
	local shouldRecharge = tick() - lastRecharge > module.RECHARGE_INTERVAL
	local shouldHeal = tick() - lastHeal > module.HEAL_INTERVAL

	local toRemove: {HealthStationServer} = {}

	for _, station in stations do
		if not station.Object:IsDescendantOf(workspace) then
			table.insert(toRemove, station)
			continue
		end

		if shouldRecharge then
			setCharge(station, station.Extras.Charge + module.RECHARGE_AMOUNT)
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

	for _, station in toRemove do
		table.remove(stations, table.find(stations, station) or error("station not found"))
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
	interactable.HintTextClient = `Charge: {charge} / {module.MAX_CHARGE}`
end

local function OnLoadClient(interactable: Types.Interactable): ()
	interactable.Object:GetAttributeChangedSignal("Charge"):Connect(function()
		updateCharge(interactable)
	end)
	updateCharge(interactable)
end

local function BeforeTakeDamage(interactable: HealthStationServer, params: Types.DamageParams?): boolean
	if not params then
		return false
	end

	local attacker = params.Attacker
	if not attacker then
		return false
	end

	return attacker:GetRole().Definition.IsBadGuys or false
end

local interactable: Types.InteractableDefinition = {
	Name = "HealthStation",
	DisplayName = "Health Station",

	Model = ReplicatedStorage.Assets.InteractableModels.HealthStation,

	InteractionRange = 7.5,
	IsContinuousInteraction = true,

	OnInteractServer = OnInteractServer,
	OnLoadServer = OnLoadServer,

	OnLoadClient = OnLoadClient,

	BeforeTakeDamage = BeforeTakeDamage,
}

module.Interactable = interactable

return module