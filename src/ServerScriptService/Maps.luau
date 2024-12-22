local ServerStorage = game:GetService("ServerStorage")
local Types = require(script.Parent.Parent.ReplicatedFirst.RoundRule.Types)

local folder = ServerStorage.Maps

local maps: {[string]: Types.Map} = {
    Skyscraper = {
        Name = "Skyscraper",
        Description = "It's a skyscraper.",
        Authors = "@louisd5",

        MapIcons = {
            ["16:9"] = "rbxassetid://123246632936403",
        },

        PlayerSpawns = folder.Skyscraper.Spawns,
        StaticMap = folder.Skyscraper.Map,

        Bounds = folder.Skyscraper.Bounds,

        DynamicMap = folder.Skyscraper.ActionItems,
        Props = folder.Skyscraper.Props,
        Windows = folder.Skyscraper.Windows,
        ItemSpawns = folder.Skyscraper.WeaponSpawns,
        
        Gravity = 80,

        MaterialVariants = folder.Skyscraper.MaterialVariants,

        LightingSettings = folder.Skyscraper.Lighting,
        WaterSettings = Instance.new("Folder"),

        TerrainColors = Instance.new("Folder"),

        AvailableItems = {},
        AvailableAmmo = {},
    },
}

return maps