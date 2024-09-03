-- Made by VroIok, last updated on 9/1/24 | Version 2.4

-- Get services
local Players = game:GetService("Players")
local soundService = game:GetService("SoundService")
local replicatedStorage = game:GetService("ReplicatedStorage")
local FootstepIDs = require(script.Parent.FootstepIDs)

-- Create sound variables
local id
local volume
local playbackSpeed

-- Create material variables
local floorMaterial
local material

-- Get remote
local updateWalkspeedRemote = replicatedStorage:WaitForChild("UpdateWalkspeed") :: RemoteEvent

-- Create sound instance
local currentSound = Instance.new("Sound", soundService)
	  currentSound.Name = "CurrentSound"

-- Get the current floor material.
local function getFloorMaterial(humanoid: Humanoid)
	floorMaterial = humanoid.FloorMaterial
	material = string.split(tostring(floorMaterial), "Enum.Material.")[2]

	return material
end

-- Get the correct sound from our sound list.
type FootstepID = {id: string, volume: number, speed: number}
local function getSoundProperties(humanoid: Humanoid)
	for name, data in FootstepIDs :: {[string]: FootstepID} do
		if name == material then
			id = data.id
			volume = data.volume / 5
			playbackSpeed = (humanoid.WalkSpeed / 16) * data.speed
			break
		end
	end
    local default = FootstepIDs.Default
    id = default.id
    volume = default.volume / 5
    playbackSpeed = (humanoid.WalkSpeed / 16) * default.speed
end

-- update the sound data
local function update()
	currentSound.SoundId = id
	currentSound.Volume = volume
	currentSound.PlaybackSpeed = playbackSpeed
end

Players.LocalPlayer.CharacterAdded:Connect(function(character)
    local humanoid = character:WaitForChild("Humanoid")
    local root = character:WaitForChild("HumanoidRootPart")
    local serverSound = root:WaitForChild("CurrentSound")

    assert(humanoid:IsA("Humanoid") and root:IsA("BasePart") and serverSound:IsA("Sound"))

    -- Update the previous floor material and current floor material
    humanoid:GetPropertyChangedSignal("FloorMaterial"):Connect(function()
        getFloorMaterial(humanoid)
        getSoundProperties(humanoid)
        update()

        if humanoid.MoveDirection.Magnitude > 0 then
            currentSound.Playing = true
        end
    end)

    -- Let the server know our walkspeed has changed
    humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
        updateWalkspeedRemote:FireServer(humanoid.WalkSpeed)
    end)

    -- check if the player is moving and not climbing
    humanoid.Running:Connect(function(speed)
        if humanoid.MoveDirection.Magnitude > 0 and speed > 0 and humanoid:GetState() ~= Enum.HumanoidStateType.Climbing then
            getSoundProperties(humanoid)
            update()
            currentSound.Playing = true
            currentSound.Looped = true
        else
            currentSound:Stop()
        end
    end)

    -- Get initial data for client
    getFloorMaterial(humanoid)
    getSoundProperties(humanoid)
    update()

    serverSound.Changed:Connect(function(Volume)
        if serverSound.Volume ~= 0 then
            serverSound.Volume = 0
        end
    end)

    -- Delete default running sound
    character:WaitForChild("HumanoidRootPart"):WaitForChild("Running"):Destroy()
end)