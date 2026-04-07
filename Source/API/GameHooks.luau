local Types = require(script.Parent.Types)

type Hooks<Callback> = {[string]: Callback}

local GameHooks = {}

GameHooks.OnDeath = {} :: Hooks<(round: Types.Round, participant: Types.Participant, defer: boolean) -> ()>

GameHooks.OnItemDropped = {} :: Hooks<(round: Types.Round, participant: Types.Participant, item: Types.Item) -> ()>

GameHooks.BeforeDamageParticipant = {} :: Hooks<(round: Types.Round, participant: Types.Participant, params: Types.DamageParams) -> ()>

GameHooks.OnCrouch = {} :: Hooks<(isCrouching: boolean) -> ()>

return GameHooks