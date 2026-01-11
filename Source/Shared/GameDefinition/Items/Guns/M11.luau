local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ItemGroups = require(ReplicatedStorage.API.ItemGroups)
local Gun = require(ReplicatedStorage.API.ItemPresets.Gun)
local ItemKillHighlights = require(ReplicatedStorage.API.ItemPresets.ItemKillHighlights)
local Ammo = require(ReplicatedStorage.API.ItemPresets.Ammo)

local M11 = Gun({
	Name = "M11",
	Description = "Rapid close range bullets.",
	IconContent = Content.none,

	ItemGroup = ItemGroups.Primary,

	Damage = {
		Head = 25,
		Body = 20,
		Limb = 15,
	},

	Spread = 0.02,

	PrimaryInterval = 0.05,
	ReloadDuration = 1,
	AmmoDefinition = Ammo.SMG1,

	Model = ReplicatedStorage.Assets.ItemModels.M11,
	HoldAnimation = Content.fromAssetId(12481091962),
	AimAnimation = Content.fromAssetId(18691799004),

	PrimarySound = ReplicatedStorage.Assets.ItemSounds.Fired.M11,
	ReloadSound = ReplicatedStorage.Assets.ItemSounds.Reload.M11,

	Projectile = ReplicatedStorage.Assets.Projectiles.Bullet,
	ProjectileSpeed = 280,

	ImpulseForce = 1,

	AimFOV = 60,
	AimSpreadMultiplier = 0.3,

	RecoilX = 0.5,
    RecoilY = 1,

    BeforeHitParticipant = ItemKillHighlights(
        {
            Title = "Pray and Slay",
            Description = "%s killed %d people with the M11, but won't say how much ammo they needed.",
            Priority = 1,
            Threshold = 2,
        },
        {
            Title = "Mac and Cheese",
            Description = "%s wonders what would happen if they could wield two M11s. %d times two?",
            Priority = 3,
            Threshold = 4,
        }
    ),
})

return M11