local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SettingsManager = require(script.Parent.SettingsManager)
local IS_SERVER = game:GetService("RunService"):IsServer()

local function createWedgeFragment(size: Vector3, cframe: CFrame, parent: BasePart, direction: Vector3)
    local wedge = Instance.new("WedgePart")
    wedge.Size = size
    wedge.CFrame = cframe
    wedge.Anchored = false
    wedge.Color = parent.Color
    wedge.Transparency = parent.Transparency
    wedge.Material = parent.Material
    wedge.MaterialVariant = parent.MaterialVariant
    wedge.Reflectance = parent.Reflectance
    wedge.CollisionGroup = "ShatteredGlass"
    wedge.BottomSurface = Enum.SurfaceType.Smooth
    wedge.CanTouch = false
    wedge.CanQuery = false
    wedge.Name = "GlassFragment"
    wedge.Parent = workspace.Projectiles

    wedge:ApplyImpulse(direction)

    return wedge
end

local sounds = {2612674531, 9103909576, 9116264426, 9113850847, 9119918457}

return function(glass: BasePart, direction: Vector3?): ()
    if IS_SERVER then
        ReplicatedStorage.ServerClient.ShatterGlass:FireAllClients(glass, direction)
        return glass:Destroy()
    end
    local cols = math.max(1, math.floor(glass.Size.X / 3))
    local rows = math.max(1, math.floor(glass.Size.Y / 3))

    local glassSize = glass.Size
    local glassCFrame = glass.CFrame

    -- Calculate the size of each fragment
    local fragmentWidth = glassSize.X / cols
    local fragmentHeight = glassSize.Y / rows
    local fragmentDepth = glassSize.Z / 2  -- Depth of the wedge (half of glass thickness)

    local fragments = {}

    -- Loop through the grid and create fragments
    for row = 0, rows - 1 do
        for col = 0, cols - 1 do
            local posX = (col * fragmentWidth) - (glassSize.X / 2) + (fragmentWidth / 2)
            local posY = (row * fragmentHeight) - (glassSize.Y / 2) + (fragmentHeight / 2)
            local posZ = 0

            local fragmentCFrame1 = glassCFrame * CFrame.new(posX, posY, posZ) * CFrame.Angles(0, math.rad(-90), 0)
            local fragmentCFrame2 = fragmentCFrame1 * CFrame.Angles(0, math.rad(180), math.rad(180))

            table.insert(fragments, createWedgeFragment(Vector3.new(fragmentDepth, fragmentHeight, fragmentWidth), fragmentCFrame1, glass, direction or (if math.random() >= 0.5 then 1 else -1) * Vector3.one))
            table.insert(fragments, createWedgeFragment(Vector3.new(fragmentDepth, fragmentHeight, fragmentWidth), fragmentCFrame2, glass, direction or (if math.random() >= 0.5 then 1 else -1) * Vector3.one))
        end
    end

    local sound = Instance.new("Sound")
    sound.SoundId = "rbxassetid://"..tostring(sounds[math.random(1, #sounds)])
    sound.RollOffMaxDistance = 200
    sound.RollOffMinDistance = 10
    sound.Parent = fragments[1]
    sound:Play()

    glass:Destroy()

    if SettingsManager.GetSetting("Keep Shattered Glass") then
        return
    end

    task.delay(5, function()
        for _, v in fragments do
            v:Destroy()
        end
        table.clear(fragments)
    end)
end