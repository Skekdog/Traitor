local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local FootstepIDs = require(script.Parent.FootstepIDs)
local IsAboveWater = require(script.Parent.IsAboveWater)
local LocalRoundInfo = require(ReplicatedStorage.Shared.LocalState.LocalRoundInfo)

type PlayerState = {
	Player: Player,
	Humanoid: Humanoid?,
	Root: BasePart?,
	CurrentSound: Sound,
	LastMaterial: Enum.Material,
}

local VOLUME_MULTIPLIER_SELF = 0.5
local VOLUME_MULTIPLIER_OTHER = 0.3
local ROLL_OFF_MIN = 3
local ROLL_OFF_MAX = 10

local playerStates: {[Player]: PlayerState?} = {}

local function createSound(): Sound
	local sound = Instance.new("Sound")
	sound.Name = "Footsteps"
	sound.Looped = true
	sound.SoundGroup = SoundService.AllSounds

	sound.RollOffMinDistance = ROLL_OFF_MIN
	sound.RollOffMaxDistance = ROLL_OFF_MAX

	return sound
end

local function createState(player: Player): PlayerState
	return {
		Player = player,
		CurrentSound = createSound(),
		LastMaterial = Enum.Material.Air,
	}
end

local map
LocalRoundInfo.Map:Connect(function(newMap)
	map = newMap
end, true)

local function getFloorMaterial(hum: Humanoid, root: BasePart): Enum.Material
	return if map and IsAboveWater(map, root, 3) then Enum.Material.Water else hum.FloorMaterial
end

local function getProperties(material: Enum.Material): FootstepIDs.FootstepData
	return FootstepIDs[material.Name] or FootstepIDs.Default
end

local function stopSound(sound: Sound): ()
	sound:Stop()
end

local function doFootstep(state: PlayerState): ()
	local hum, root, currentSound, lastMaterial = state.Humanoid, state.Root, state.CurrentSound, state.LastMaterial
	if not hum or not root then
		return stopSound(currentSound)
	end

	if hum.MoveDirection.Magnitude <= 0 then
		return stopSound(currentSound)
	end

	local newMaterial = getFloorMaterial(hum, root)

	if hum:GetAttribute("IsCrouching") and newMaterial ~= Enum.Material.Water then
		return stopSound(currentSound)
	end

	local properties = getProperties(newMaterial)

	currentSound.PlaybackSpeed = properties.speed * (hum.WalkSpeed / 16)

	if newMaterial == lastMaterial then
		if not currentSound.IsPlaying then
			currentSound:Play()
		end
		return
	end

	state.LastMaterial = newMaterial

	currentSound.SoundId = properties.id
	currentSound.Volume = properties.volume * (if state.Player == Players.LocalPlayer then VOLUME_MULTIPLIER_OTHER else VOLUME_MULTIPLIER_SELF)
	currentSound:Play()
end

RunService.PostSimulation:Connect(function()
	for _, state in playerStates do
		assert(state)
		doFootstep(state)
	end
end)

local function onCharacterAdded(character: Model, state: PlayerState): ()
	local root = character:WaitForChild("HumanoidRootPart")
	local hum = character:WaitForChild("Humanoid")

	assert(root:IsA("BasePart") and hum:IsA("Humanoid"), "Invalid humanoid or root part")

	state.Root = root
	state.Humanoid = hum

	state.CurrentSound.Parent = if state.Player == Players.LocalPlayer then SoundService else root

	task.spawn(function()
		root:WaitForChild("Running"):Destroy()
	end)
end

local function onPlayerAdded(player: Player): ()
	local state = createState(player)
	playerStates[player] = state

	player.CharacterAdded:Connect(function(character)
		onCharacterAdded(character, state)
	end)

	player.CharacterRemoving:Connect(function()
		state.Root = nil
		state.Humanoid = nil
		state.CurrentSound.Parent = nil
	end)

	if player.Character then
		onCharacterAdded(player.Character, state)
	end

	player.Destroying:Connect(function()
		playerStates[player] = nil
	end)
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in Players:GetPlayers() do
	onPlayerAdded(player)
end

return nil