local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ItemGroups = require(ReplicatedStorage.API.ItemGroups)
local Gun = require(ReplicatedStorage.API.Item.Presets.Gun)
local ItemKillHighlights = require(ReplicatedStorage.API.Item.Behaviour.KillHighlights)
local Ammo = require(ReplicatedStorage.API.Item.Ammo)

local M11 = Gun({
	Name = "M11",
	Description = "Rapid close range bullets.",
	IconContent = Content.fromAssetId(74794323083210),

	ItemGroup = ItemGroups.Primary,

	Damage = {
		Head = 20,
		Body = 10,
		Limb = 5,
	},

	Spread = 0.02,

	PrimaryInterval = 0.065,
	ReloadDuration = 1,
	AmmoDefinition = Ammo["Sub-Spec"],

	Model = ReplicatedStorage.Assets.ItemModels.M11,
	HoldAnimation = Content.fromAssetId(12481091962),
	AimAnimation = Content.fromAssetId(18691799004),

	PrimarySound = ReplicatedStorage.Assets.ItemSounds.Fired.M11,
	ReloadSound = ReplicatedStorage.Assets.ItemSounds.Reload.M11,

	Projectile = ReplicatedStorage.Assets.Projectiles.Bullet,
	ProjectileSpeed = 280,

	ImpulseForce = 1,

	HasMuzzleFlash = true,
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

return table.freeze(M11)