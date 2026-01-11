local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ItemGroups = require(ReplicatedStorage.API.ItemGroups)
local Gun = require(ReplicatedStorage.API.ItemPresets.Gun)
local ItemKillHighlights = require(ReplicatedStorage.API.ItemPresets.ItemKillHighlights)
local Ammo = require(ReplicatedStorage.Shared.GameDefinition.Items.Ammo)

local FiveSeven = Gun({
	Name = "Five-Seven",
    Description = "Sadder version of the Deagle.",
    IconContent = Content.none,

    ItemGroup = ItemGroups.Secondary,

    Damage = {
        Head = 60,
        Body = 30,
        Limb = 20,
    },

    Spread = 0.01,

    AimSpreadMultiplier = 0.1,

    PrimaryInterval = 0.5,
    ReloadDuration = 1,
    AmmoType = Ammo["9mm"],

    ImpulseForce = 5,

    Model = ReplicatedStorage.Assets.ItemModels["Five-Seven"],
    HoldAnimation = Content.fromAssetId(9253211833),
    AimAnimation = Content.fromAssetId(18691552315),
    PrimarySound = ReplicatedStorage.Assets.ItemSounds.Fired["Five-Seven"],
    ReloadSound = ReplicatedStorage.Assets.ItemSounds.Reload["Five-Seven"],

    BeforeHitParticipant = ItemKillHighlights(
        {
            Title = "Persistent Little Bugger",
            Description = "%s scored %d kills using the pistol. Then they went on to hug someone to death.",
            Priority = 1,
            Threshold = 2,
        },
        {
            Title = "Small Caliber Slaughter",
            Description = "%s killed a small army of %d with a pistol. Presumably installed a tiny shotgun inside the barrel.",
            Priority = 3,
            Threshold = 4,
        }
    ),

    Projectile = ReplicatedStorage.Assets.Projectiles.Bullet,
    ProjectileSpeed = 250,

    RecoilX = 0.2,
    RecoilY = 1.0,
})

return FiveSeven