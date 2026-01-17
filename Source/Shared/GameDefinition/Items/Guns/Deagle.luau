local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ItemGroups = require(ReplicatedStorage.API.ItemGroups)
local Gun = require(ReplicatedStorage.API.ItemPresets.Gun)
local ItemKillHighlights = require(ReplicatedStorage.API.ItemPresets.ItemKillHighlights)
local Ammo = require(ReplicatedStorage.API.ItemPresets.Ammo)

local Deagle = Gun({
	Name = "Deagle",
	Description = "Bang, bang, bang!",
	IconContent = Content.none,

    ItemGroup = ItemGroups.Secondary,

    Damage = {
        Head = 100,
        Body = 40,
        Limb = 20,
    },

    HasMuzzleFlash = true,

    AimFOV = 50,
    AimSpreadMultiplier = 0.1,

    PrimaryInterval = 0.5,
    ReloadDuration = 1.2,
    AmmoDefinition = Ammo["High-Cal"],

    Projectile = ReplicatedStorage.Assets.Projectiles.Bullet,
    ProjectileSpeed = 450,

    ImpulseForce = 15,

    Model = ReplicatedStorage.Assets.ItemModels.Deagle,
    HoldAnimation = Content.fromAssetId(9253211833),
    AimAnimation = Content.fromAssetId(18691552315),
    PrimarySound = ReplicatedStorage.Assets.ItemSounds.Fired.Deagle,
    ReloadSound = ReplicatedStorage.Assets.ItemSounds.Reload.Deagle,

    RecoilX = 0.3,
    RecoilY = 1.2,

    BeforeHitParticipant = ItemKillHighlights(
        {
            Title = "It's Like A Tiny Rifle",
            Description = "%s is getting the hang of the Desert Eagle and killed %d people.",
            Priority = 1,
            Threshold = 2,
        },
        {
            Title = "Eagle Master",
            Description = "%s blew away %d people with the deagle.",
            Priority = 3,
            Threshold = 4,
        }
    ),
})

return Deagle