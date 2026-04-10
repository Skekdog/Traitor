local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local Audio = require(ReplicatedStorage.API.Audio)
local RoundHandler = require(ServerScriptService.RoundHandler)
local Types = require(ReplicatedStorage.API.Types)
local GetTaggedDescendants = require(ReplicatedStorage.Shared.RoundRule.Common.GetTaggedDescendants)

local DROWN_THRESHOLD = 10
local DROWN_DAMAGE = 10
local DROWN_INTERVAL = 1

local DROWN_SOUND = Audio.MakeSound({
	Content = Content.fromAssetId(220194561),
	RolloffEnd = 20,
	RolloffStart = 15,
})

local params = RaycastParams.new()
params.IgnoreWater = false
params.FilterType = Enum.RaycastFilterType.Include
params.CollisionGroup = "PlayerCharacterParts" -- so that we include bounds

type Participant = Types.Participant & {
	Extras: {
		DrownElapsed: number?,
		LastDrownAt: number?,
	}
}

local function doDrown(participant: Participant, head: BasePart): ()
	Audio.PlayIn(DROWN_SOUND, head, false, "Drown")

	participant:TryTakeDamage({
		Amount = DROWN_DAMAGE,
		Source = "Drown",
	})

	participant.Extras.LastDrownAt = os.clock()
end

local function forEachParticipant(participant: Participant, dt: number, map: Types.Map): ()
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

	local isSubmerged = false
	if humanoid:GetState() == Enum.HumanoidStateType.Swimming then
		local include = GetTaggedDescendants(map.Structure, "Water")
		table.insert(include, workspace.Terrain)
		params.FilterDescendantsInstances = include

		local result = workspace:Raycast(head.Position, Vector3.new(0, -1.5, 0), params)

		if not result then
			-- If we are underwater, then raycasting returns nothing as the ray is starting in the water object
			isSubmerged = true
		elseif result.Instance == workspace.Terrain and result.Material ~= Enum.Material.Water then
			-- If we hit something and it isn't water then we are at the sea floor
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

	doDrown(participant, head)
end

RunService.Heartbeat:Connect(function(dt)
	local round = RoundHandler.GetRound()

	local map = round._map
	if not map then
		return
	end

	for _, v in round:GetParticipants() do
		assert(v)
		forEachParticipant(v, dt, map)
	end
end)

return nil