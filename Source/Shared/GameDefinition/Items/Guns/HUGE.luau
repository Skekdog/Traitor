local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ItemGroups = require(ReplicatedStorage.API.ItemGroups)
local Gun = require(ReplicatedStorage.API.ItemPresets.Gun)
local ItemKillHighlights = require(ReplicatedStorage.API.ItemPresets.ItemKillHighlights)
local Ammo = require(ReplicatedStorage.API.ItemPresets.Ammo)

local HUGE = Gun({
	Name = "HUGE",
	Description = "Yes, I like this gun.",
	IconContent = Content.none,

    ItemGroup = ItemGroups.Primary,

    Spread = 0.1,
    HasMuzzleFlash = true,

    Damage = {
        Head = 10,
        Body = 5,
        Limb = 2,
    },

    AimFOV = 60,
    AimSpreadMultiplier = 0.9,

    PrimaryInterval = 0.01,

    Projectile = ReplicatedStorage.Assets.Projectiles.Bullet,
    ProjectileSpeed = 280,

    ImpulseForce = 1,

    Model = ReplicatedStorage.Assets.ItemModels.HUGE,
    HoldAnimation = Content.fromAssetId(12498608892),
    AimAnimation = Content.fromAssetId(18691844030),

    PrimarySound = ReplicatedStorage.Assets.ItemSounds.Fired.HUGE,

    RecoilX = 1.5,
    RecoilY = 2.5,

    AmmoDefinition = Ammo.HUGE,

    BeforeHitParticipant = ItemKillHighlights(
        {
            Title = "A HUGE Spread",
            Description = "%s was in tune with their HUGE, somehow managing to make their bullets hit %d people.",
            Priority = 1,
            Threshold = 2,
        },
        {
            Title = "A Patient Para",
            Description = "%s just kept firing, and saw their HUGE patience rewarded with %d kills.",
            Priority = 3,
            Threshold = 4,
        }
    )
})

return HUGE