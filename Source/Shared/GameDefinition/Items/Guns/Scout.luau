local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ItemGroups = require(ReplicatedStorage.API.ItemGroups)
local Gun = require(ReplicatedStorage.API.Item.Presets.Gun)
local ItemKillHighlights = require(ReplicatedStorage.API.Item.Behaviour.KillHighlights)
local Ammo = require(ReplicatedStorage.API.Item.Ammo)

local Scout = Gun({
	Name = "Scout",
	Description = "Boom, headshot!",
	IconContent = Content.none,

    ItemGroup = ItemGroups.Primary,

    AimFOV = 30,
    AimSpreadMultiplier = 0.05,
    IsScopable = true,

    Damage = {
        Body = 50,
        Limb = 25,
        Head = 150,
    },

    Projectile = ReplicatedStorage.Assets.Projectiles.Bullet,
    ProjectileSpeed = 250,

    ImpulseForce = 20,

    PrimaryInterval = 1,
    ReloadDuration = 1.5,
    AmmoDefinition = Ammo.Rifle,

    Model = ReplicatedStorage.Assets.ItemModels.Scout,
    HoldAnimation = Content.fromAssetId(10247529531),
    AimAnimation = Content.fromAssetId(18691492037),
    PrimarySound = ReplicatedStorage.Assets.ItemSounds.Fired.Scout,
    ReloadSound = ReplicatedStorage.Assets.ItemSounds.Reload.Scout,

    BeforeHitParticipant = ItemKillHighlights(
        {
            Title = "Point and Click",
            Description = "%s shows all you need for %d kills is a rifle and a steady hand.",
            Priority = 1,
            Threshold = 2,
        },
        {
            Title = "I Can See Your Head From Here",
            Description = "%s knows their rifle. Now %d other people know the rifle too.",
            Priority = 3,
            Threshold = 4,
        }
    ),

    RecoilX = 0.5,
    RecoilY = 1.5,
})

return table.freeze(Scout)