local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local FootstepIDs = require(script.Parent.FootstepIDs)
local Crouch = require(ReplicatedStorage.Shared.Actions.Crouch)
local IsAboveWater = require(script.Parent.IsAboveWater)
local LocalRoundInfo = require(ReplicatedStorage.Shared.LocalState.LocalRoundInfo)
local LocalCharacter = require(script.Parent.LocalCharacter)

local hum
LocalCharacter.Humanoid:Connect(function(newHum)
	hum = newHum
end, true)

local root
LocalCharacter.RootPart:Connect(function(newRoot)
	root = newRoot

	if root then
		root:WaitForChild("Running"):Destroy()
	end
end, true)

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

local lastMaterial = Enum.Material.Air

local currentSound = Instance.new("Sound")
currentSound.Name = "ClientFootsteps"
currentSound.Looped = true
currentSound.SoundGroup = SoundService.AllSounds
currentSound.Parent = SoundService

local function stopSound(): ()
	currentSound:Stop()
end

RunService.PostSimulation:Connect(function()
	if not hum or not root then
		return stopSound()
	end

	if hum.MoveDirection.Magnitude <= 0 or Crouch.IsCrouching() then
		return stopSound()
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

	lastMaterial = newMaterial

	currentSound.SoundId = properties.id
	currentSound.Volume = properties.volume / 5
	currentSound:Play()
end)

return nil