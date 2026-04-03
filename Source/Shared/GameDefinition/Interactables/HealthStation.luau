local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local DNATraces = require(ReplicatedStorage.API.DNATraces)
local BlockFriendlyDamage = require(ReplicatedStorage.API.Prop.BlockFriendlyDamage)
local Types = require(ReplicatedStorage.API.Types)

local module = {}
module.MAX_CHARGE = 200
module.HEAL_INTERVAL = 0.5
module.HEAL_AMOUNT = 1
module.RECHARGE_INTERVAL = 2.5
module.RECHARGE_AMOUNT = 1

type HealthStationServer = Types.Prop & {
	Interactable: Types.InteractableDefinition,
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
	interactable.Model:SetAttribute("Charge", interactable.Extras.Charge)
end

local function OnInteractServer(interactable: Types.Prop, participant: Types.Participant): ()
	local station = interactable :: HealthStationServer

	local charge = station.Extras.Charge or module.MAX_CHARGE
	local humanoid = participant:GetHumanoid()
	if not humanoid or participant:GetHealth() >= humanoid.MaxHealth then
		return
	end

	if charge < module.HEAL_AMOUNT then
		if not station.Extras.NoChargeSound.IsPlaying then
			station.Extras.NoChargeSound:Play()
		end
		return
	end

	table.insert(station.Extras.HealQueue, participant)
end

local function OnLoadServer(interactable: Types.Prop): ()
	local station = interactable :: HealthStationServer

	setCharge(station, module.MAX_CHARGE)
	station.Extras.HealQueue = {}
	table.insert(stations, station)

	local healSound = Instance.new("Sound")
	healSound.SoundId = "rbxassetid://4720447470"
	healSound.RollOffMinDistance = 5
	healSound.RollOffMaxDistance = 15
	healSound.PlaybackRegionsEnabled = true
	healSound.PlaybackRegion = NumberRange.new(0.2, 1.19)
	healSound.Parent = station.Model

	station.Extras.HealSound = healSound

	local noChargeSound = Instance.new("Sound")
	noChargeSound.SoundId = "rbxassetid://72729349003330"
	noChargeSound.RollOffMinDistance = 5
	noChargeSound.RollOffMaxDistance = 15
	noChargeSound.Parent = station.Model

	station.Extras.NoChargeSound = noChargeSound
end

local function heal(interactable: Types.Prop, participant: Types.Participant): ()
	local station = interactable :: HealthStationServer

	participant.Extras.HealthStationLastHealedAt = os.clock()
	participant:SetHealth(participant:GetHealth() + module.HEAL_AMOUNT)
	setCharge(station, station.Extras.Charge - module.HEAL_AMOUNT)

	if not station.Extras.HealSound.IsPlaying then
		station.Extras.HealSound:Play()
	end

	DNATraces.Add(station, participant, nil, Content.fromAssetId(93284379186217), station.Model)
end

local lastRecharge = 0
local lastHeal = 0
RunService.Heartbeat:Connect(function()
	local shouldRecharge = os.clock() - lastRecharge > module.RECHARGE_INTERVAL
	local shouldHeal = os.clock() - lastHeal > module.HEAL_INTERVAL

	local toRemove: {HealthStationServer} = {}

	for _, station in stations do
		if not station.Model:IsDescendantOf(workspace) then
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
		lastRecharge = os.clock()
	end

	if shouldHeal then
		lastHeal = os.clock()
	end
end)

local function updateCharge(interactable: Types.Prop): ()
	local charge = interactable.Model:GetAttribute("Charge") :: number?
	interactable.HintTextClient = `Charge: {charge} / {module.MAX_CHARGE}`
end

local function OnLoadClient(interactable: Types.Prop): ()
	interactable.Model:GetAttributeChangedSignal("Charge"):Connect(function()
		updateCharge(interactable)
	end)
	updateCharge(interactable)
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

	BeforeTakeDamage = BlockFriendlyDamage,
}

module.Interactable = interactable

return table.freeze(module)