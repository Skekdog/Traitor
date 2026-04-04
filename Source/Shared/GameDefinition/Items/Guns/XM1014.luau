local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ItemGroups = require(ReplicatedStorage.API.ItemGroups)
local Gun = require(ReplicatedStorage.API.Item.Presets.Gun)
local ItemKillHighlights = require(ReplicatedStorage.API.Item.Behaviour.KillHighlights)
local Ammo = require(ReplicatedStorage.API.Item.Ammo)

local XM1014 = Gun({
    Name = "XM1014",
	Description = "Haha boomstick",
	IconContent = Content.fromAssetId(91158225550994),

    ItemGroup = ItemGroups.Primary,

    Damage = {
        Head = 15,
        Body = 10,
        Limb = 5,
    },

    HasMuzzleFlash = true,

    AimFOV = 50,
    AimSpreadMultiplier = 0.7,

    Spread = 0.03,

    PrimaryInterval = 0.8,
    ReloadDuration = 1.5,
    AmmoDefinition = Ammo.Shotgun,

    ProjectileCount = 8,

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

return table.freeze(XM1014)