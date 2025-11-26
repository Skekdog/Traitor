local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Ammo = require(script.Parent.Ammo)
local Types = require(ReplicatedStorage.API.Types)
local ItemGroups = require(ReplicatedStorage.Shared.GameDefinition.Items.Common.ItemGroups)

local MelonLauncher = {}

local model = Instance.new("Part")
model.Name = "MelonLauncher"

local item: Types.GunWeaponDefinition = {
	Kind = "Gun" :: "Gun",

	Name = "MelonLauncher",
	DisplayName = "Melon Launcher",
	Description = "boom",
	Icon = "",

	Model = model,
	HoldAnimation = "rbxassetid://132951688645757",

	CanDrop = true,
	CreditCost = 1,
	MaxStock = 1,

	IsEvilItem = true,

	ItemGroup = ItemGroups.RoleWeapon,

	PhysicallySimulated = true,

	Damage = 50,
	Spread = 1,

	AmmoType = Ammo.MelonLauncher,
	AttackInterval = 1.5,

	RecoilX = 10,
	RecoilY = 10,

	ReloadTime = 0,
}

MelonLauncher.Item = item

return MelonLauncher