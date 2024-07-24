local ReplicatedFirst = game:GetService("ReplicatedFirst")
local CreateEmptyPart = require(ReplicatedFirst.CreateEmptyPart)

type SoundId = number | Sound | string

local random = Random.new()
return function(sound: SoundId | {SoundId}, position: Vector3): Sound
    local part = CreateEmptyPart(CFrame.new(position))

    if typeof(sound) == "table" then
        random:Shuffle(sound)
        sound = sound[1]
    end

    local soundObject: Sound
    if typeof(sound) == "Instance" then
        soundObject = sound:Clone()
    else
        local soundId: string
        if typeof(sound) == "number" then
            soundId = "rbxassetid://" .. sound
        elseif typeof(sound) == "string" then
            soundId = sound
        end

        soundObject = Instance.new("Sound")
        soundObject.SoundId = soundId
    end

    soundObject.Volume = 1

    soundObject.Parent = part
    part.Parent = workspace.Projectiles

    soundObject.Ended:Connect(function()
        part:Destroy()
    end)
    soundObject:Play()

    return soundObject
end
