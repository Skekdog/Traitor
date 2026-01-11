local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ItemGroups = require(ReplicatedStorage.API.ItemGroups)
local Gun = require(ReplicatedStorage.API.ItemPresets.Gun)
local ItemKillHighlights = require(ReplicatedStorage.API.ItemPresets.ItemKillHighlights)
local Ammo = require(ReplicatedStorage.Shared.GameDefinition.Items.Ammo)

local XM1014 = Gun({
    Name = "XM1014",
	Description = "Haha boomstick",
	IconContent = Content.none,

    ItemGroup = ItemGroups.Primary,

    Damage = {
        Head = 30,
        Body = 18,
        Limb = 10,
    },

    HasMuzzleFlash = true,

    AimFOV = 50,
    AimSpreadMultiplier = 0.7,

    Spread = 0.03,

    PrimaryInterval = 0.8,
    ReloadDuration = 1.5,
    AmmoType = Ammo.Shotgun,

    BulletsPerShot = 6,

    Projectile = ReplicatedStorage.Assets.Projectiles.Bullet,
    ProjectileSpeed = 220,

    ImpulseForce = 4,

    Model = ReplicatedStorage.Assets.ItemModels.XM1014,
    HoldAnimation = Content.fromAssetId(11436160569),
    AimAnimation = Content.fromAssetId(18691725191),
    PrimarySound = ReplicatedStorage.Assets.ItemSounds.Fired.XM1014,
    ReloadSound = ReplicatedStorage.Assets.ItemSounds.Reload.XM1014,

    BeforeHitParticipant = ItemKillHighlights(
        {
            Title = "Easy Mode",
            Description = "%s applies the buckshot where it hurts, murdering %d targets.",
            Priority = 1,
            Threshold = 2,
        },
        {
            Title = "A Thousand Little Pellets",
            Description = "%s didn't really like their buckshot, so they gave it all away. %d recipients did not live to enjoy it.",
            Priority = 3,
            Threshold = 4,
        }
    ),

    RecoilX = 1.0,
    RecoilY = 2.0,
})

return XM1014