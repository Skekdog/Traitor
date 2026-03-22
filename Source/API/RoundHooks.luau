local Types = require(script.Parent.Types)

type Hooks<Callback> = {[string]: Callback}

local RoundHooks = {}

RoundHooks.OnDeath = {} :: Hooks<(round: Types.Round, participant: Types.Participant, defer: boolean) -> ()>

RoundHooks.OnItemDropped = {} :: Hooks<(round: Types.Round, participant: Types.Participant, defer: Types.Item) -> ()>

RoundHooks.BeforeDamageParticipant = {} :: Hooks<(round: Types.Round, participant: Types.Participant, params: Types.DamageParams) -> ()>

return RoundHooks