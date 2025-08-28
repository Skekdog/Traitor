local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local PlaySound = require(ReplicatedStorage.Shared.RoundRule.Common.PlaySound)
local Settings = require(ReplicatedStorage.Shared.Settings.Settings)

local IS_SERVER = game:GetService("RunService"):IsServer()

local DEFAULT_FORCE = 2

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

    direction *= math.random(0.9, 1.1)
    wedge:ApplyImpulse(direction)

    return wedge
end

local sounds = {2612674531, 9103909576, 9116264426, 9113850847, 9119918457}

export type GlassProperties = {
    CFrame: CFrame,
    Size: Vector3,

    Material: Enum.Material,
    MaterialVariant: string,

    Color: Color3,
    Transparency: number,
    Reflectance: number,
}

local function shatterServer(glassProperties: BasePart | GlassProperties, direction: Vector3?, force: number?): ()
    assert(typeof(glassProperties) == "Instance")

    local properties = {
        CFrame = glassProperties.CFrame,
        Size = glassProperties.Size * Vector3.new(0.9, 0.9, 0.05),

        Material = glassProperties.Material,
        MaterialVariant = glassProperties.MaterialVariant,

        Color = glassProperties.Color,
        Transparency = glassProperties.Transparency,
        Reflectance = glassProperties.Reflectance,
    }

    ReplicatedStorage.Remotes.ServerClient.ShatterGlass:FireAllClients(properties, direction, force)

    glassProperties:Destroy()
end

local function shatterClient(glassProperties: BasePart | GlassProperties, direction: Vector3?, force: number?): ()
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
                fragmentCFrame1, (direction or ((if math.random() >= 0.5 then 1 else -1) * Vector3.one)) * (force or DEFAULT_FORCE))
            )
            table.insert(fragments,
                createWedgeFragment(glassProperties, Vector3.new(fragmentDepth, fragmentHeight, fragmentWidth),
                fragmentCFrame2, (direction or ((if math.random() >= 0.5 then 1 else -1) * Vector3.one)) * (force or DEFAULT_FORCE))
            )
        end
    end

    PlaySound(sounds, glassCFrame.Position, nil, {
        RollOffMaxDistance = 50,
        RollOffMinDistance = 10,
        RollOffMode = Enum.RollOffMode.Linear,
        SoundGroup = SoundService.AllSounds :: SoundGroup,
    })

    if Settings.GetSetting("Keep Shattered Glass") then
        return
    end

    task.delay(5, function()
        for _, v in fragments do
            v:Destroy()
        end
        table.clear(fragments)
    end)
end

local function ShatterGlass(glassProperties: BasePart | GlassProperties, direction: Vector3?, force: number?): ()
    if IS_SERVER then
        return shatterServer(glassProperties, direction, force)
    end
    shatterClient(glassProperties, direction, force)
end

if not IS_SERVER then
    ReplicatedStorage.Remotes.ServerClient.ShatterGlass.OnClientEvent:Connect(ShatterGlass)
end

return ShatterGlass