
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Ammo = require(script.Parent.Ammo)
local Types = require(ReplicatedStorage.RoundRule.Types)

local item: Types.GunWeaponDefinition = {
	Kind = "Gun" :: "Gun",
	Name = "Poltergeist",
	Description = "Attaches thrusters to props, blasting them towards others.",
	Icon = "rbxassetid://103677163409705",

	Model = ReplicatedStorage.WeaponModels.Poltergeist,

	HoldAnimation = "rbxassetid://10247380824",

	Slot = 8,
	MaxStock = 2,
	CreditCost = 1,
	CanDrop = true,

	Damage = 0,

	Spread = 0,

	AttackInterval = 3,
	ReloadTime = 0,
	AmmoType = Ammo["Poltergeist"],

	AttackSound = "",
	ReloadSound = "",

	RecoilX = 0,
	RecoilY = 0,
}

return item