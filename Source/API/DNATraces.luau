local DamageSource = require(script.Parent.DamageSource)
local GameHooks = require(script.Parent.GameHooks)
local Types = require(script.Parent.Types)

local DNATraces = {}

local MAX_KILL_DISTANCE = 60
local MAX_KILL_TRACE_DURATION = 120

export type IHasDNATraces = {
	Extras: {
		DNATraces: {DNATrace}?,
		[any]: never,
	},
}

export type IHasObject = {
	Object: Instance,
}

export type IHasTarget = {
	Target: string
}

export type DNATrace = IHasTarget & IHasObject & {
	ExpiresAt: number?,
	Icon: string,
}

type Participant = Types.Participant & IHasDNATraces

function DNATraces.HasEquivalentTrace(t: {IHasTarget & IHasObject}, trace: IHasTarget & IHasObject): boolean
	for _, existingTrace in t do
		if existingTrace.Target == trace.Target and existingTrace.Object == trace.Object then
			return true
		end
	end
	return false
end

function DNATraces.Add(object: IHasDNATraces, target: Types.Participant, duration: number?, icon: Content, instance: Instance): ()
	local traces = object.Extras.DNATraces or {}

	local trace: DNATrace = {
		ExpiresAt = if duration then workspace:GetServerTimeNow() + duration else nil,
		Target = target.Player.Name,
		Icon = icon.Uri or "",
		Object = instance,
	}

	if DNATraces.HasEquivalentTrace(traces, trace) then
		return
	end

	table.insert(traces, trace)

	object.Extras.DNATraces = traces
end

function DNATraces.Remove(object: IHasDNATraces): ()
	object.Extras.DNATraces = nil
end

function DNATraces.Get(object: IHasDNATraces): {DNATrace}
	return object.Extras.DNATraces or {}
end

GameHooks.OnDeath["DNATraces"] = function(round: Types.Round, participant: Types.Participant, deferVictoryCheck: boolean): ()
	local corpse = participant.Corpse
	if not corpse then
		return
	end

	local attacker = corpse.Killer
	if not attacker then
		return
	end

	if (attacker:HasSelfDefenseAgainstParticipant(participant) and not participant:GetRole().Definition.CorpseHidesSelfDefense) or participant:IsFreeKill(attacker) then
		return
	end

	local char = corpse.Model
	if not char then
		return
	end

	local isEligible = DamageSource.IsFirearm(corpse.CorpseView.DamageSource) or DamageSource.IsMelee(corpse.CorpseView.DamageSource)
	if not isEligible then
		return
	end

	local distance = attacker.Player:DistanceFromCharacter(char:GetPivot().Position)
	if distance == 0 then
		return
	end

	local duration = math.lerp(MAX_KILL_TRACE_DURATION, 0, distance / MAX_KILL_DISTANCE)
	DNATraces.Add(participant, attacker, duration, Content.fromAssetId(1043921089), char)

	participant:AddCorpseIcon({
		Name = "DNATrace",
		Icon = Content.fromAssetId(135886260297010),
		Description = "Traces of the killer's DNA are on the body. Use a DNA Scanner to track them.",
		DisplayText = `[TIMEUNTIL-{tostring(workspace:GetServerTimeNow() + duration)}]`,
	})
end

GameHooks.OnItemDropped["DNATraces"] = function(round: Types.Round, participant: Types.Participant, item: Types.Item)
	if not item.Model then
		return
	end
	DNATraces.Add(item, participant, nil, item.IconContent or Content.fromAssetId(4795275417), item.Model)
end

return table.freeze(DNATraces)