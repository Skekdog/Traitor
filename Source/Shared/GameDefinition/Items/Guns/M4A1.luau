local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ItemGroups = require(ReplicatedStorage.API.ItemGroups)
local Gun = require(ReplicatedStorage.API.Item.Presets.Gun)
local ItemKillHighlights = require(ReplicatedStorage.API.Item.Behaviour.KillHighlights)
local Ammo = require(ReplicatedStorage.API.Item.Ammo)

local M4A1 = Gun({
	Name = "M4A1",
	Description = "Powerful mid-range assault rifle.",
	IconContent = Content.fromAssetId(97287553447708),

	ItemGroup = ItemGroups.Primary,

	Spread = 0.015,

	Damage = {
		Head = 60,
		Body = 30,
		Limb = 20,
	},

	PrimaryInterval = 0.19,

	ReloadDuration = 1.5,
	AmmoDefinition = Ammo["Mil-Spec"],

	HasMuzzleFlash = true,
	AimFOV = 50,

	AimSpreadMultiplier = 0.25,

	Model = ReplicatedStorage.Assets.ItemModels.M4A1,
	HoldAnimation = Content.fromAssetId(10247380824),
	AimAnimation = Content.fromAssetId(18691831450),

	PrimarySound = ReplicatedStorage.Assets.ItemSounds.Fired.M4A1,
	ReloadSound = ReplicatedStorage.Assets.ItemSounds.Reload.M4A1,

	Projectile = ReplicatedStorage.Assets.Projectiles.Bullet,
	ProjectileSpeed = 250,

	ImpulseForce = 5,

	RecoilX = 0.6,
	RecoilY = 1.5,

	BeforeHitParticipant = ItemKillHighlights(
        {
            Title = "Putt Putt Putt",
            Description = "%s picked off %d people with the M4A1.",
            Priority = 1,
            Threshold = 2,
        },
        {
            Title = "Mid-range Madness",
            Description = "%s knows how to take down targets with the M4A1, scoring %d kills.",
            Priority = 3,
            Threshold = 4,
        }
    ),
})

return table.freeze(M4A1)