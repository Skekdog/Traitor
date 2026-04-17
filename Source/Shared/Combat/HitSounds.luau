local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Audio = require(ReplicatedStorage.API.Audio)
local plasticSounds = {8666684617, 9118587494, 82708037443413}
local metalSounds = {7842407959, 4072627278, 2303101209}
local woodSounds = {8542226017, 8542224235, 8542224819, 8542225504, 8542223682}
local fabricSounds = {106969093871170, 9118771226, 9099672443}
local glassSounds = {3207457473, 9119937112, 9119596406}
local groundSounds = {6876730610, 6876735204, 6877211005, 6877211445}
local fruitSounds = {9114540315, 9114539908, 9114542474, 9114540327, 9114541282}

local soundsFolder = ReplicatedStorage:FindFirstChild("HitSounds") :: Folder? or Instance.new("Folder")
soundsFolder.Name = "HitSounds"
soundsFolder.Parent = ReplicatedStorage

local function create(tbl: {number}): {Sound}
    local sounds: {Sound} = {}
    for _, id in tbl do
        if RunService:IsServer() then
            local sound = Audio.MakeSound({
                Content = Content.fromAssetId(id),
                Name = tostring(id),
                RolloffStart = 10,
                RolloffEnd = 20,
            })
            sound.Parent = soundsFolder
            table.insert(sounds, sound)
        else
            local sound = soundsFolder:FindFirstChild(tostring(id))
            assert(sound and sound:IsA("Sound"))
            table.insert(sounds, sound)
        end
    end

    return sounds
end

return {
    Default = create(plasticSounds),

    Fruit = create(fruitSounds),
    Body = create(fruitSounds),
    Water = create(fruitSounds),

    -- Carpet stuff
    Fabric = create(fabricSounds),
    Carpet = create(fabricSounds),
    Sand = create(fabricSounds),
    Leather = create(fabricSounds),

    -- Wood stuff
    Wood = create(woodSounds),
    WoodPlanks = create(woodSounds),
    CardboardBox = create(woodSounds),
    WoodCrate = create(woodSounds),
    WoodBox = create(woodSounds),
    WoodPanel = create(woodSounds),

    -- Metal stuff
    Metal = create(metalSounds),
    CorrodedMetal = create(metalSounds),
    DiamondPlate = create(metalSounds),
    MetalBox = create(metalSounds),
    MetalGrate = create(metalSounds),
    Computer = create(metalSounds),

    -- Glass stuff
    Glass = create(glassSounds),
    Glacier = create(glassSounds),
    Ice = create(glassSounds),

    -- Ground stuff
    Ground = create(groundSounds),
    Grass = create(groundSounds),
    LeafyGrass = create(groundSounds),
    Mud = create(groundSounds),
    Dirt = create(groundSounds),
} :: {[string]: {Sound}?, Default: {Sound}}