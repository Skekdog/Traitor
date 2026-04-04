local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local SoundService = game:GetService("SoundService")
local GetTaggedDescendants = require(ReplicatedStorage.Shared.RoundRule.Common.GetTaggedDescendants)
local PlaySound = require(ReplicatedStorage.API.PlaySound)
local RoundHandler = require(ServerScriptService.RoundHandler)
local Types = require(ReplicatedStorage.API.Types)

local DROWN_THRESHOLD = 10
local DROWN_DAMAGE = 10
local DROWN_INTERVAL = 1

local params = RaycastParams.new()
params.IgnoreWater = false
params.FilterDescendantsInstances = {workspace.Terrain}
params.IgnoreWater = false
params.FilterType = Enum.RaycastFilterType.Include

type Participant = Types.Participant & {
	Extras: {
		DrownElapsed: number?,
		LastDrownAt: number?,
	}
}

local overlapParams = OverlapParams.new()
overlapParams.RespectCanCollide = false
overlapParams.FilterType = Enum.RaycastFilterType.Include
overlapParams.FilterDescendantsInstances = {workspace.Characters}

local function forEachParticipant(participant: Participant, dt: number, alreadySubmerged: boolean?): ()
	local char = participant:GetCharacter()
	if not char then
		return
	end

	local humanoid = participant:GetHumanoid()
	if not humanoid then
		return
	end

	if not participant:IsAlive() then
		return
	end

	local head = char:FindFirstChild("Head")
	if not head or not head:IsA("BasePart") then
		return
	end

	local isSubmerged = alreadySubmerged

	if not isSubmerged and humanoid:GetState() == Enum.HumanoidStateType.Swimming then
		local result = workspace:Raycast(head.Position, Vector3.new(0, -0.5, 0), params)

		-- So this looks silly, but if we are under water then raycasting will return nothing, since the ray already started under water
		if not result then
			isSubmerged = true
		end
	end

	if not isSubmerged then
		participant.Extras.DrownElapsed = 0
		return
	end

	if os.clock() - (participant.Extras.LastDrownAt or 0) < DROWN_INTERVAL then
		return
	end

	local elapsed = (participant.Extras.DrownElapsed or 0) + dt
	participant.Extras.DrownElapsed = elapsed

	if elapsed < DROWN_THRESHOLD then
		return
	end

	PlaySound(220194561, nil, head, {
		SoundGroup = SoundService.AllSounds :: SoundGroup,
		RollOffMinDistance = 15,
		RollOffMaxDistance = 20,
	})

	participant:TryTakeDamage({
		Amount = DROWN_DAMAGE,
		Source = "Drown",
	})

	participant.Extras.LastDrownAt = os.clock()
end

RunService.Heartbeat:Connect(function(dt)
	local round = RoundHandler.GetRound()

	local map = round._map
	if not map then
		return
	end

	local submergedParticipants: {[Participant]: true?} = {}

	for _, bound in GetTaggedDescendants(map.Structure, "Water") do
		if not bound:IsA("BasePart") then
			return
		end

		local size = Vector3.new(bound.Size.X, math.max(bound.Size.Y - 0.5, 0), bound.Size.Z)

		for _, v in workspace:GetPartBoundsInBox(bound.CFrame, size, overlapParams) do
			if v.Name ~= "Head" then
				continue
			end

			local character = v:FindFirstAncestorOfClass("Model")
			if not character then
				continue
			end

			local participant = round:GetParticipant(character.Name)
			if not participant then
				continue
			end

			submergedParticipants[participant] = true
		end
	end

	for _, v in round:GetParticipants() do
		assert(v)
		forEachParticipant(v, dt, submergedParticipants[v])
	end
end)

return nil