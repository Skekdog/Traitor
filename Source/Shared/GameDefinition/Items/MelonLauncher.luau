local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Ammo = require(script.Parent.Ammo)
local Types = require(ReplicatedStorage.API.Types)
local ItemGroups = require(ReplicatedStorage.Shared.GameDefinition.Items.Common.ItemGroups)
local PlaySound = require(ReplicatedStorage.API.PlaySound)

local MelonLauncher = {}

local function BeforeHitAnything(_, _, _, params: Types.DamageParams): boolean
	local Combat = require(ReplicatedStorage.API.Combat)
	assert(params.Attacker and params.HitPosition)
	Combat.MakeExplosion({
		Attacker = params.Attacker,
		Position = params.HitPosition,
		Damage = 50,
		FalloffEnd = 15,
		FalloffBegin = 5,
	}, Instance.new("Sound"))
	return true
end

local item: Types.GunWeaponDefinition = {
	Kind = "Gun" :: "Gun",

	Name = "MelonLauncher",
	DisplayName = "Melon Launcher",
	Description = "boom",
	Icon = "",

	Model = ReplicatedStorage.Assets.WeaponModels.MelonLauncher,
	HoldAnimation = "rbxassetid://4772214897",

	AttackSound = PlaySound.MakeSound(7129285090),

	CanDrop = true,
	CreditCost = 1,
	MaxStock = 1,

	IsEvilItem = true,

	ItemGroup = ItemGroups.RoleWeapon,

	IsPhysicallySimulated = true,

	Projectile = ReplicatedStorage.Assets.Projectiles.Watermelon,
	ProjectileSpeed = 100,

	Damage = 50,
	Spread = 0.03,

	AmmoType = Ammo.MelonLauncher,
	AttackInterval = 1.5,

	RecoilX = 10,
	RecoilY = 10,

	ReloadTime = 0,

	BeforeHitAnything = BeforeHitAnything,
}

MelonLauncher.Item = item

return MelonLauncher