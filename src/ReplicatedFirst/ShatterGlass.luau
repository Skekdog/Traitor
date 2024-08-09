local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SettingsManager = require(script.Parent.SettingsManager)
local IS_SERVER = game:GetService("RunService"):IsServer()

local function createWedgeFragment(properties: GlassProperties, size: Vector3, cframe: CFrame, direction: Vector3)
    local wedge = Instance.new("WedgePart")

    for i, v in properties do
        if i ~= "Size" and i ~= "CFrame" then
            (wedge :: any)[i] = v 
        end
    end

    wedge.Size = size
    wedge.CFrame = cframe

    wedge.Anchored = false
    wedge.CanTouch = false
    wedge.CanQuery = false
    
    wedge.CollisionGroup = "ShatteredGlass"
    wedge.BottomSurface = Enum.SurfaceType.Smooth
    
    wedge.Name = "GlassFragment"
    wedge.Parent = workspace.Projectiles

    wedge:ApplyImpulse(direction)

    return wedge
end

local sounds = {2612674531, 9103909576, 9116264426, 9113850847, 9119918457}

type GlassProperties = {
    CFrame: CFrame,
    Size: Vector3,

    Material: Enum.Material,
    MaterialVariant: string,

    Color: Color3,
    Transparency: number,
    Reflectance: number,
}

return function(glassProperties: BasePart | GlassProperties, direction: Vector3?): ()
    if IS_SERVER then
        assert(typeof(glassProperties) == "Instance")

        local properties = {
            CFrame = glassProperties.CFrame,
            Size = glassProperties.Size,

            Material = glassProperties.Material,
            MaterialVariant = glassProperties.MaterialVariant,

            Color = glassProperties.Color,
            Transparency = glassProperties.Transparency,
            Reflectance = glassProperties.Reflectance,
        }

        ReplicatedStorage.ServerClient.ShatterGlass:FireAllClients(properties, direction)
        return glassProperties:Destroy()
    end
    assert(typeof(glassProperties) == "table")

    local cols = math.max(1, math.floor(glassProperties.Size.X / 3))
    local rows = math.max(1, math.floor(glassProperties.Size.Y / 3))

    local glassSize = glassProperties.Size
    local glassCFrame = glassProperties.CFrame

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

            table.insert(fragments,
                createWedgeFragment(glassProperties, Vector3.new(fragmentDepth, fragmentHeight, fragmentWidth),
                fragmentCFrame1, direction or (if math.random() >= 0.5 then 1 else -1) * Vector3.one)
            )
            table.insert(fragments,
                createWedgeFragment(glassProperties, Vector3.new(fragmentDepth, fragmentHeight, fragmentWidth),
                fragmentCFrame2, direction or (if math.random() >= 0.5 then 1 else -1) * Vector3.one)
            )
        end
    end

    local sound = Instance.new("Sound")
    sound.SoundId = "rbxassetid://"..tostring(sounds[math.random(1, #sounds)])
    sound.RollOffMaxDistance = 200
    sound.RollOffMinDistance = 10
    sound.Parent = fragments[1]
    sound:Play()

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