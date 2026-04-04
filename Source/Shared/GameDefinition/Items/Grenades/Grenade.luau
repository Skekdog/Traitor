local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ItemGroups = require(ReplicatedStorage.API.ItemGroups)
local Grenade = require(ReplicatedStorage.API.Item.Presets.Grenade)
local PlaySound = require(ReplicatedStorage.API.PlaySound)

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

        Sound = PlaySound.MakeSound(110846649787027, {
            Volume = 0.75,
            RollOffMinDistance = 40,
            RollOffMaxDistance = 75,
        })
    },

    FuseTime = 5,

    PrimarySound = ReplicatedStorage.Assets.ItemSounds.Fired.Grenade,
})

return table.freeze(item)