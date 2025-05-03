local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Participant = require(ReplicatedStorage.RoundRule.Participant)
local Types = require(ReplicatedStorage.RoundRule.Types)

local module = {}

local MAX_KILL_DISTANCE = 60
local MAX_KILL_TRACE_DURATION = 120

function module.AddDNATrace(object: IHasDNATraces, target: Types.Participant, duration: number?): ()
	local traces = object.Extras.DNATraces or {}
	table.insert(traces, {
		ExpiresAt = if duration then workspace:GetServerTimeNow() + duration else nil,
		Target = target.Player.Name,
	})
	object.Extras.DNATraces = traces
end

export type IHasDNATraces = {
	Extras: {
		DNATraces: {DNATrace}?,
	},
}

type DNATrace = {
	ExpiresAt: number,
	Target: string,
}

type Participant = Types.Participant & IHasDNATraces

local originalOnDeath = Participant.OnDeath
local function patchedOnDeath(participant: Participant, params: Types.DamageParams, deferVictoryCheck: boolean): ()
	local attacker = params.Attacker
	if not attacker then
		return
	end

	if attacker:HasSelfDefenseAgainstParticipant(participant) then
		return
	end

	local char = participant:GetCharacter()
	if not char then
		return
	end

	local source: Types.DamageSource = params.Source
	local isEligible = true-- source == "Shot" or source == "Bludgeon" or source == "Stab" or if typeof(source) == "table" then source.Kind == "Gun" or source.Kind == "Melee" else false
	if not isEligible then
		return
	end

	local distance = attacker.Player:DistanceFromCharacter(char:GetPivot().Position)
	if distance == 0 then
		return
	end

	local duration = math.lerp(MAX_KILL_TRACE_DURATION, 0, distance / MAX_KILL_DISTANCE)
	module.AddDNATrace(participant, attacker, duration)

	participant:AddCorpseIcon({
		Name = "DNATrace",
		Icon = "rbxassetid://135886260297010",
		Description = "Traces of the killer's DNA are on the body. Use a DNA Scanner to track them.",
		DisplayText = `[TIMEUNTIL-{tostring(workspace:GetServerTimeNow() + duration)}]`,
	})
end

Participant.OnDeath = function(participant: Types.Participant, params: Types.DamageParams, deferVictoryCheck: boolean): ()
	patchedOnDeath(participant, params, deferVictoryCheck)
	originalOnDeath(participant, params, deferVictoryCheck)
end

local item: Types.ItemDefinition = {
	Kind = "Item" :: "Item",
	Name = "DNAScanner",
	DisplayName = "DNA Scanner",

	Slot = 9,
	CanDrop = true,

	Model = ReplicatedStorage.WeaponModels["DNA Scanner"],
	HoldAnimation = "rbxassetid://10247423634",

	PrimaryHint = "Scan Identified Body",
}

return item