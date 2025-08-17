local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local SoundService = game:GetService("SoundService")
local PlaySound = require(ReplicatedStorage.Shared.RoundRule.Common.PlaySound)
local RoundHandler = require(ServerScriptService.RoundHandler)
local Types = require(ReplicatedStorage.Shared.RoundRule.Types)

local DROWN_THRESHOLD = 10
local DROWN_DAMAGE = 10
local DROWN_INTERVAL = 1

local params = RaycastParams.new()
params.IgnoreWater = false
params.FilterDescendantsInstances = {workspace.Terrain}
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
	if tick() - (participant.Extras.LastDrownAt or 0) < DROWN_INTERVAL then
		return
	end

	if not participant:IsAlive() then
		return
	end

	local char = participant:GetCharacter()
	if not char then
		return
	end

	local head = char:FindFirstChild("Head")
	if not head or not head:IsA("BasePart") then
		return
	end

	local isSubmerged = alreadySubmerged

	if not isSubmerged then
		local roundedPos = (Vector3.new(math.round(head.Position.X), math.round(head.Position.Y), math.round(head.Position.Z)) // 4) * 4
		local voxels = workspace.Terrain:ReadVoxelChannels(Region3.new(roundedPos, roundedPos + Vector3.one * 4), 4, {"LiquidOccupancy"})
		local occupancy = voxels.LiquidOccupancy[1][1][1]
		isSubmerged = occupancy > 0
	end

	if not isSubmerged then
		participant.Extras.DrownElapsed = 0
		return
	end

	local elapsed = (participant.Extras.DrownElapsed or 0) + dt
	participant.Extras.DrownElapsed = elapsed

	if elapsed < DROWN_THRESHOLD then
		return
	end

	PlaySound(220194561, nil, head, {
		SoundGroup = SoundService.AllSounds :: SoundGroup,
		RollOffMinDistance = 5,
		RollOffMaxDistance = 10,
	})

	participant:TryTakeDamage({
		Amount = DROWN_DAMAGE,
		Source = "Drown",
	})

	participant.Extras.LastDrownAt = tick()
end

RunService.Heartbeat:Connect(function(dt)
	local round = RoundHandler.GetRound()

	local map = round._map
	if not map then
		return
	end

	local submergedParticipants: {[Participant]: true?} = {}

	for _, bound in CollectionService:GetTagged("WaterLoaded") do
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