-- Made by VroIok, last updated on 9/1/24 | Version 2.4

-- Get services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local FootstepIDs = require(script.Parent.Parent.ReplicatedFirst.FootstepIDs)

local function update(currentSound: Sound, id: string, volume: number, playbackSpeed: number)
    currentSound.SoundId = id
    currentSound.Volume = volume / 5
    currentSound.PlaybackSpeed = playbackSpeed
end

local function getFloorMaterial(humanoid: Humanoid): (string, Enum.Material)
    local floorMaterial = humanoid.FloorMaterial
    local material = string.split(tostring(floorMaterial), "Enum.Material.")[2]

    return material, floorMaterial
end

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(character)
        local currentSound = Instance.new("Sound")
        currentSound.Name = "CurrentSound"
        currentSound.RollOffMode = Enum.RollOffMode.Linear -- you can experiment with this value
        currentSound.RollOffMinDistance = 5 -- When should the sound start fading out? (in studs)
        currentSound.RollOffMaxDistance = 20 -- When should the sound stop being heard? (in studs)
        currentSound.Parent = character.PrimaryPart

        local humanoid = character:WaitForChild("Humanoid") :: Humanoid
        local lastFloorMaterial = humanoid.FloorMaterial
        
        local function getSoundProperties(humanoid: Humanoid, material: string): (string, number, number)
            for name, data in pairs(FootstepIDs) do
                if name == material then
                    return data.id, data.volume, (humanoid.WalkSpeed / 16) * data.speed
                end
            end
            return FootstepIDs.Default.id, FootstepIDs.Default.volume, (humanoid.WalkSpeed / 16) * FootstepIDs.Default.speed
        end

        -- check if the player is moving and not climbing
        humanoid.Running:Connect(function(speed)
            if humanoid.MoveDirection.Magnitude > 0 and speed > 0 and humanoid:GetState() ~= Enum.HumanoidStateType.Climbing then
                getSoundProperties(humanoid, (getFloorMaterial(humanoid)))
                update(currentSound, getSoundProperties(humanoid, (getFloorMaterial(humanoid))))
                currentSound.Playing = true
                currentSound.Looped = true
            else
                currentSound:Stop()
            end
        end)

        local serverFix = coroutine.create(function()
            while task.wait() do
                if humanoid.FloorMaterial ~= lastFloorMaterial then
                    local mat, flMat = getFloorMaterial(humanoid)
                    lastFloorMaterial = flMat
                    getSoundProperties(humanoid, mat)
                    update(currentSound, getSoundProperties(humanoid, mat))
                end
            end
        end)

        coroutine.resume(serverFix)

        player.CharacterRemoving:Connect(function()
            coroutine.close(serverFix)
        end)
    end)
end)

local updateWalkspeedRemote = ReplicatedStorage:FindFirstChild('UpdateWalkspeed')
updateWalkspeedRemote.OnServerEvent:Connect(function(player, walkspeed)
    local char = player.Character
    if not char then
        return
    end

    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then
        return
    end

    hum.WalkSpeed = walkspeed
end)