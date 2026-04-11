local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Audio = require(ReplicatedStorage.API.Audio)
local ItemGroups = require(ReplicatedStorage.API.ItemGroups)
local Grenade = require(ReplicatedStorage.API.Item.Presets.Grenade)

local item = Grenade({
	Name = "Grenade",
    Description = "Explodes in a good radius after 5 seconds.",
    IconContent = Content.fromAssetId(8096856961),

    Cost = 2,
    MaxStock = 2,

    IsSuspicious = true,

    ItemGroup = ItemGroups.RoleWeapon,

    Projectile = ReplicatedStorage.Assets.Projectiles.Grenade,
    Model = ReplicatedStorage.Assets.ItemModels.Grenade,
    HoldAnimation = Content.fromAssetId(12498620263),

    ExplosionInfo = {
        Damage = 200,
        FalloffStart = 5,
        FalloffEnd = 17,
        Pressure = 50000,
        VisualRadius = 17,

        Sound = Audio.MakeSound({
            Content = Content.fromAssetId(110846649787027),
            Volume = 0.75,
            RolloffStart = 40,
            RolloffEnd = 75,
        })
    },

    FuseTime = 5,

    PrimarySound = ReplicatedStorage.Assets.ItemSounds.Fired.Grenade,
})

return table.freeze(item)