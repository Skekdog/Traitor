local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ItemGroups = require(ReplicatedStorage.API.ItemGroups)
local Gun = require(ReplicatedStorage.API.ItemPresets.Gun)
local Ammo = require(ReplicatedStorage.API.ItemPresets.Ammo)

local BAR = Gun({
	Name = "BAR",
    Description = "A powerful mid-range rifle. Slow to reload.",
    IconContent = Content.fromAssetId(10243797417),

    MaxStock = 3,

    IsEvilItem = true,

    ItemGroup = ItemGroups.Primary,
    Cost = 1,

    ImpulseForce = 15,

    Damage = {
        Head = 75,
        Body = 40,
        Limb = 25,
    },

    Spread = 0.02,

    PrimaryInterval = 0.1,
    ReloadDuration = 2.5,
    AmmoType = Ammo["9mm"],

    Model = ReplicatedStorage.Assets.ItemModels.BAR,
    HoldAnimation = Content.fromAssetId(10247380824),
    AimAnimation = Content.fromAssetId(18691831450),
    PrimarySound = ReplicatedStorage.Assets.ItemSounds.Fired.BAR,
    ReloadSound = ReplicatedStorage.Assets.ItemSounds.Reload.BAR,

    Projectile = ReplicatedStorage.Assets.Projectiles.Bullet,
    ProjectileSpeed = 280,

    AimFOV = 65,
    AimSpreadMultiplier = 0.2,

    RecoilX = 0.6,
    RecoilY = 1.8,
})

return BAR