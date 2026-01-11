local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ItemGroups = require(ReplicatedStorage.API.ItemGroups)
local Gun = require(ReplicatedStorage.API.ItemPresets.Gun)
local Ammo = require(ReplicatedStorage.Shared.GameDefinition.Items.Ammo)

local G18 = Gun({
	Name = "G18",
	Description = "Small arms go brrrr",
	IconContent = Content.none,

    ItemGroup = ItemGroups.Secondary,

    Damage = {
        Head = 20,
        Body = 15,
        Limb = 10,
    },

    HasMuzzleFlash = true,

    AimFOV = 70,
    AimSpreadMultiplier = 0.1,

    Spread = 0.01,

    PrimaryInterval = 0.1,
    ReloadTime = 1,
    AmmoType = Ammo["9mm"],

    Model = ReplicatedStorage.Assets.ItemModels.G18,
    HoldAnimation = Content.fromAssetId(9253211833),
    AimAnimation = Content.fromAssetId(18691552315),
    AttackSound = ReplicatedStorage.Assets.ItemSounds.Fired.G18,
    ReloadSound = ReplicatedStorage.Assets.ItemSounds.Reload.G18,

    Projectile = ReplicatedStorage.Assets.Projectiles.Bullet,
    ProjectileSpeed = 280,

    ImpulseForce = 3,

    RecoilX = 0.2,
    RecoilY = 0.8,
})

return G18