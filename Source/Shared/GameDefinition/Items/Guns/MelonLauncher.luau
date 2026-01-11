local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Ammo = require(script.Parent.Ammo)
local Types = require(ReplicatedStorage.API.Types)
local ItemGroups = require(ReplicatedStorage.Shared.GameDefinition.Items.Common.ItemGroups)

local MelonLauncher = {}

local function reduceAmount(_, _, hitParticipant: Types.Participant, params: Types.DamageParams): boolean
	if hitParticipant == params.Attacker then
		params.Amount /= 5
	end
	return true
end

local function BeforeHitAnything(_, _, _, params: Types.DamageParams): boolean
	local Combat = require(ReplicatedStorage.API.Combat)
	assert(params.Attacker and params.HitPosition)
	Combat.MakeExplosion({
		Attacker = params.Attacker,
		Position = params.HitPosition,
		Damage = 50,
		FalloffEnd = 15,
		FalloffBegin = 5,
		Pressure = 100000,

		BeforeHitParticipant = reduceAmount,
	})
	return true
end

local item: Types.GunWeaponDefinition = {
	Kind = "Gun" :: "Gun",

	Name = "MelonLauncher",
	DisplayName = "Melon Launcher",
	Description = "Launches explosive melons.",
	Icon = "rbxassetid://4793387432",

	Model = ReplicatedStorage.Assets.WeaponModels.MelonLauncher,
	HoldAnimation = "rbxassetid://10247529531",

	AttackSound = ReplicatedStorage.Assets.WeaponSounds.Fired["Melon Launcher"],

	CanDrop = true,
	CreditCost = 1,
	MaxStock = 1,

	IsEvilItem = true,

	ItemGroup = ItemGroups.RoleWeapon,

	IsPhysicallySimulated = true,

	Projectile = ReplicatedStorage.Assets.Projectiles.Watermelon,
	ProjectileSpeed = 100,

	Damage = 50,
	Spread = 0.01,

	AmmoType = Ammo.MelonLauncher,
	AttackInterval = 1.5,

	RecoilX = 10,
	RecoilY = 10,

	ReloadTime = 0,

	BeforeHitAnything = BeforeHitAnything,
	BeforeHitParticipant = reduceAmount,
}

MelonLauncher.Item = item

return MelonLauncher