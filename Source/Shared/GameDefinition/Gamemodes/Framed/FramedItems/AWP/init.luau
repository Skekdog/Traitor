local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StandardGame = require(ReplicatedStorage.API.StandardGame)
local Items = require(ReplicatedStorage.API.StandardGame)

local AWP = {}

local Item = Items.CopyModify(Items.GetItem("AWP"), "AWP", {
	Description = "A high-powered sniper rifle.",
	ScopeRequired = false,
	AmmoType = StandardGame.GetAmmo("Rifle"),
	CreditCost = 3,
	ReloadTime = 1.5,
	Spread = 0.04,
	AimSpreadMultiplier = 0.01,
	ReloadSound = (ReplicatedStorage.Assets:WaitForChild("WeaponSounds"):WaitForChild("Reload"):WaitForChild("Scout") :: Sound),
})

AWP.Item = Item

return AWP