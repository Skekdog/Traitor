local Types = require(script.Parent.Types)

local DNATraces = {}

export type HasDNATraces = {
	Extras: {
		DNATraces: {DNATrace}?,
		[any]: never,
	},
}

export type DNATrace = {
	Object: Instance,
	Target: string,
	ExpiresAt: number?,
	Icon: Content,
}

type Participant = Types.Participant & HasDNATraces

function DNATraces.HasEquivalentTrace(traces: {DNATrace}, trace: DNATrace): boolean
	for _, existingTrace in traces do
		if existingTrace.Target == trace.Target and existingTrace.Object == trace.Object then
			return true
		end
	end
	return false
end

function DNATraces.Add(object: HasDNATraces, target: Types.Participant, duration: number?, icon: Content, instance: Instance): ()
	local traces = object.Extras.DNATraces or {}

	local trace: DNATrace = {
		ExpiresAt = if duration then workspace:GetServerTimeNow() + duration else nil,
		Target = target.Player.Name,
		Icon = icon,
		Object = instance,
	}

	if DNATraces.HasEquivalentTrace(traces, trace) then
		return
	end

	table.insert(traces, trace)

	object.Extras.DNATraces = traces
end

function DNATraces.Remove(object: HasDNATraces): ()
	object.Extras.DNATraces = nil
end

function DNATraces.Get(object: HasDNATraces): {DNATrace}
	return object.Extras.DNATraces or {}
end

return table.freeze(DNATraces)