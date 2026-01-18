local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Discombobulate = require(ReplicatedStorage.API.Discombobulate)
local ItemGroups = require(ReplicatedStorage.API.ItemGroups)
local Gun = require(ReplicatedStorage.API.Item.Presets.Gun)
local Ammo = require(ReplicatedStorage.API.Item.Ammo)

local UMP = Gun({
	Name = "UMP",
    Description = "A weak weapon standalone, but loaded with discombobulation. Targets will be disorientated when hit. Uses SMG rounds.",
    IconContent = Content.fromAssetId(8482220999),

    MaxStock = 2,
    Cost = 1,
    ItemGroup = ItemGroups.RoleWeapon,

    Damage = {
        Head = 25,
        Body = 15,
        Limb = 10,
    },

    Spread = 0.01,

    PrimaryInterval = 0.1,
    ReloadDuration = 1.5,
    AmmoDefinition = Ammo["Sub-Spec"],

    Model = ReplicatedStorage.Assets.ItemModels.UMP,
    HoldAnimation = Content.fromAssetId(10247380824),
    AimAnimation = Content.fromAssetId(18691831450),
	PrimarySound = ReplicatedStorage.Assets.ItemSounds.Fired.UMP,
    ReloadSound = ReplicatedStorage.Assets.ItemSounds.Reload.UMP,

    Projectile = ReplicatedStorage.Assets.Projectiles.Bullet,
    ProjectileSpeed = 250,

    ImpulseForce = 5,

    OnHitClient = Discombobulate,

    RecoilX = 0.75,
    RecoilY = 1.75,
})

return UMP