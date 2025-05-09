local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Types = require(ReplicatedStorage.Shared.RoundRule.Types)

local DROWN_THRESHOLD = 10
local DROWN_DAMAGE_PER_SECOND = 10

local heads: {[BasePart]: Types.Participant} = {}

local params = RaycastParams.new()
params.IgnoreWater = false
params.FilterDescendantsInstances = {workspace.Characters}
params.FilterType = Enum.RaycastFilterType.Exclude

type Participant = Types.Participant & {
	Extras: {
		DrownElapsed: number?,
	}
}

local function forEachHead(head: BasePart, participant: Participant, dt: number): ()
	local result = workspace:Raycast(head.Position, Vector3.new(0, -0.1, 0), params)
	if not result then
		return
	end

	if result.Material ~= Enum.Material.Water then
		return
	end

	local elapsed = (participant.Extras.DrownElapsed or 0) + dt
	participant.Extras.DrownElapsed = elapsed

	if elapsed < DROWN_THRESHOLD then
		return
	end

	if participant.Round:GetParticipant(participant.Player.Name) ~= participant then
		return
	end

	participant:TryTakeDamage({
		Amount = DROWN_DAMAGE_PER_SECOND * dt,
		Source = "Drown",
	})
end

RunService.Heartbeat:Connect(function(dt)
	for head, participant in heads do
		forEachHead(head, participant, dt)
	end


end)

return nil