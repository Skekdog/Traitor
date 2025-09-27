local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Items = require(ReplicatedStorage.API.StandardGame)
local Ammo = require(ReplicatedStorage.Shared.GameDefinition.Items.Ammo)

local AWP = {}

local Item = Items.CopyModify(Items.GetItem("AWP"), "AWP", {
	Description = "A high-powered sniper rifle.",
	ScopeRequired = false,
	AmmoType = Ammo.Rifle,
	CreditCost = 3,
	ReloadTime = 1.5,
	Spread = 0.04,
	AimSpreadMultiplier = 0.01,
	ReloadSound = (ReplicatedStorage.Assets:WaitForChild("WeaponSounds"):WaitForChild("Reload"):WaitForChild("Scout") :: Sound),
})

AWP.Item = Item

return AWP