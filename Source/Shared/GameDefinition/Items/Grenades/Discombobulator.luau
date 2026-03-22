local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Discombobulate = require(ReplicatedStorage.API.Discombobulate)
local ItemGroups = require(ReplicatedStorage.API.ItemGroups)
local Grenade = require(ReplicatedStorage.API.Item.Presets.Grenade)

local Discombobulator = Grenade({
	Name = "Discombobulator",
	Description = "Oh I'm so discombobulated",
	IconContent = Content.none,

    ItemGroup = ItemGroups.Grenade,

    Projectile = ReplicatedStorage.Assets.Projectiles.Discombobulator,
    HoldAnimation = Content.fromAssetId(12498620263),
    Model = ReplicatedStorage.Assets.ItemModels.Discombobulator,

    ExplosionInfo = {
        Damage = 0,
        FalloffStart = 0,
        FalloffEnd = 15,
        Pressure = 75000,
        VisualRadius = 15,
    },

    OnHitClient = Discombobulate,

    FuseTime = 3,

    PrimarySound = ReplicatedStorage.Assets.ItemSounds.Fired.Grenade,
})

return table.freeze(Discombobulator)