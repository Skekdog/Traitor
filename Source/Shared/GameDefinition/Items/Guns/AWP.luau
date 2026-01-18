local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ItemGroups = require(ReplicatedStorage.API.ItemGroups)
local Gun = require(ReplicatedStorage.API.Item.Presets.Gun)
local ItemKillHighlights = require(ReplicatedStorage.API.Item.Behaviour.KillHighlights)
local Ammo = require(ReplicatedStorage.API.Item.Ammo)

local AWP = Gun({
	Name = "AWP",
    Description = "A high-powered sniper rifle. Must be scoped in to shoot.",
    IconContent = Content.fromAssetId(4772214897),

    MaxStock = 1,

    IsEvilItem = true,

    ItemGroup = ItemGroups.RoleWeapon,
    Cost = 1,

    Damage = {
        Head = 300,
        Body = 100,
        Limb = 65,
    },

    ImpulseForce = 50,

    AmmoDefinition = Ammo.AWP,

    AimFOV = 10,
    AimSpreadMultiplier = 0.05,
    IsScopable = true,
    IsScopeRequired = true,

    PrimaryInterval = 2,

    Model = ReplicatedStorage.Assets.ItemModels.AWP,
    HoldAnimation = Content.fromAssetId(10247529531),
    AimAnimation = Content.fromAssetId(18691492037),
    PrimarySound = ReplicatedStorage.Assets.ItemSounds.Fired.AWP,

    Projectile = ReplicatedStorage.Assets.Projectiles.Bullet,
    ProjectileSpeed = 600,

    RecoilX = 0.8,
    RecoilY = 2.5,

    BeforeHitParticipant = ItemKillHighlights(
		{
			Title = "Good Job",
			Description = "%s killed 1 person with an AWP.",
			Priority = 2,
			Threshold = 1,
		},
        {
			Title = "Good Job",
			Description = "%s killed %d people with an AWP.",
			Priority = 3,
			Threshold = 2,
		},
		{
			Title = "Challenging Work",
			Description = "%s killed %d people with an AWP. Possibly out of doors.",
			Priority = 4,
			Threshold = 3,
		}
	)
})

return AWP