local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.API.Types)
local Gun = require(ReplicatedStorage.API.Item.Presets.Gun)
local ItemGroups = require(ReplicatedStorage.API.ItemGroups)
local Ammo = require(ReplicatedStorage.API.Item.Ammo)

local MelonLauncher = {}

local function reduceAmount(_, params: Types.DamageParams, hitParticipant: Types.Participant): boolean
	if hitParticipant == params.Attacker then
		params.Amount /= 5
	end
	return true
end

local function BeforeHitAnything(_, params: Types.DamageParams): boolean
	local Combat = require(ReplicatedStorage.API.Combat)
	assert(params.Attacker and params.HitPosition)
	Combat.MakeExplosion({
		Attacker = params.Attacker,
		Position = params.HitPosition,
		Damage = 50,
		FalloffEnd = 15,
		FalloffStart = 5,
		Pressure = 100000,

		BeforeHitParticipant = reduceAmount,
	})
	return true
end

MelonLauncher.Item = Gun({
	Name = "MelonLauncher",
	DisplayName = "Melon Launcher",
	Description = "Launches explosive melons.",
	IconContent = Content.fromAssetId(4793387432),

	Model = ReplicatedStorage.Assets.ItemModels.MelonLauncher,
	HoldAnimation = Content.fromAssetId(10247529531),

	IsAimable = false,

	PrimarySound = ReplicatedStorage.Assets.ItemSounds.Fired["Melon Launcher"],

	Cost = 1,
	MaxStock = 1,

	IsEvilItem = true,

	ItemGroup = ItemGroups.RoleWeapon,

	IsProjectileSimulated = true,

	Projectile = ReplicatedStorage.Assets.Projectiles.Watermelon,
	ProjectileSpeed = 100,

	Damage = 50,
	Spread = 0.01,

	AmmoDefinition = Ammo.MelonLauncher,
	PrimaryInterval = 1.5,

	RecoilX = 10,
	RecoilY = 10,

	BeforeHitAnything = BeforeHitAnything,
	BeforeHitParticipant = reduceAmount,
})

return MelonLauncher