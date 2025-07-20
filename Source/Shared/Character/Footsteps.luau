local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local FootstepIDs = require(script.Parent.FootstepIDs)
local IsAboveWater = require(script.Parent.IsAboveWater)
local LocalRoundInfo = require(ReplicatedStorage.Shared.LocalState.LocalRoundInfo)

type PlayerState = {
	Humanoid: Humanoid?,
	Root: BasePart?,
	CurrentSound: Sound,
	LastMaterial: Enum.Material,
}

local VOLUME_MULTIPLIER = 0.5

local playerStates: {[Player]: PlayerState?} = {}

local function createSound(): Sound
	local sound = Instance.new("Sound")
	sound.Name = "Footsteps"
	sound.Looped = true
	sound.SoundGroup = SoundService.AllSounds
	return sound
end

local function createState(): PlayerState
	return {
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

	if hum.MoveDirection.Magnitude <= 0 or hum:GetAttribute("IsCrouching") then
		return stopSound(currentSound)
	end

	local newMaterial = getFloorMaterial(hum, root)
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
	currentSound.Volume = properties.volume * VOLUME_MULTIPLIER
	currentSound:Play()
end

RunService.PostSimulation:Connect(function()
	for _, state in playerStates do
		assert(state)
		doFootstep(state)
	end
end)

local function onCharacterAdded(character: Model, state: PlayerState, player: Player): ()
	local root = character:WaitForChild("HumanoidRootPart")
	local hum = character:WaitForChild("Humanoid")

	assert(root:IsA("BasePart") and hum:IsA("Humanoid"), "Invalid humanoid or root part")

	state.Root = root
	state.Humanoid = hum

	state.CurrentSound.Parent = if player == Players.LocalPlayer then SoundService else root

	task.spawn(function()
		root:WaitForChild("Running"):Destroy()
	end)
end

local function onPlayerAdded(player: Player): ()
	local state = createState()
	playerStates[player] = state

	player.CharacterAdded:Connect(function(character)
		onCharacterAdded(character, state, player)
	end)

	player.CharacterRemoving:Connect(function()
		state.Root = nil
		state.Humanoid = nil
		state.CurrentSound.Parent = nil
	end)

	if player.Character then
		onCharacterAdded(player.Character, state, player)
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