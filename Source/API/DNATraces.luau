local Types = require(script.Parent.Types)

local DNATraces = {}

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

return table.freeze(DNATraces)