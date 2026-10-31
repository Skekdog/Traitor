local Types = require(script.Parent.Types)

type Hooks<Callback> = {[string]: Callback}

local GameHooks = {}

GameHooks.OnDeath = {} :: Hooks<(round: Types.Round, participant: Types.Participant) -> ()>

GameHooks.OnPhaseChanged = {} :: Hooks<(round: Types.Round, phase: Types.Phase) -> ()>

GameHooks.OnRoleAssigned = {} :: Hooks<(round: Types.Round, participant: Types.Participant, role: Types.Role) -> ()>

GameHooks.OnItemDropped = {} :: Hooks<(round: Types.Round, participant: Types.Participant, item: Types.Item) -> ()>

GameHooks.BeforeDamageParticipant = {} :: Hooks<(round: Types.Round, participant: Types.Participant, params: Types.DamageParams) -> ()>

GameHooks.OnCrouch = {} :: Hooks<(isCrouching: boolean) -> ()>

return GameHooks