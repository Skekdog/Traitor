local plasticSounds = {110741119564229, 8666684617}
local metalSounds = {7842407959, 4072627278, 2303101209}
local woodSounds = {8542226017, 8542224235, 8542224819, 8542225504, 8542223682}
local fabricSounds = {6636232274, 2706199011, 9118771226}
local glassSounds = {3207457473, 9119937112, 9119596406}
local groundSounds = {6876730610, 6876735204, 6877211005, 6877211445}
return {
    Default = plasticSounds,
    
    Fruit = {9114540315, 9114539908, 9114542474, 9114540327, 9114541282},

    -- Carpet stuff
    Fabric = fabricSounds,
    Carpet = fabricSounds,
    Sand = fabricSounds,
    
    -- Wood stuff
    Wood = woodSounds,
    WoodPlanks = woodSounds,

    -- Metal stuff
    Metal = metalSounds,
    CorrodedMetal = metalSounds,
    DiamondPlate = metalSounds,

    -- Glass stuff
    Glass = glassSounds,
    Glacier = glassSounds,
    Ice = glassSounds,

    -- Ground stuff
    Ground = groundSounds,
    Grass = groundSounds,
    LeafyGrass = groundSounds,
    Mud = groundSounds,
}