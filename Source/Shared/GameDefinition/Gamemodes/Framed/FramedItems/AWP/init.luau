local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Modify = require(ReplicatedStorage.API.Modify)
local StandardGame = require(ReplicatedStorage.API.StandardGame)

local AWP = {}

local Item = Modify(StandardGame.GetItem("AWP"), "AWP", {
	Description = "A high-powered sniper rifle.",
	IsScopeRequired = false,
	AmmoDefinition = StandardGame.GetAmmo("Rifle"),
	Cost = 3,
	ReloadDuration = 1.5,
	Spread = 0.04,
	AimSpreadMultiplier = 0.01,
	ReloadSound = (ReplicatedStorage.Assets:WaitForChild("ItemSounds"):WaitForChild("Reload"):WaitForChild("Scout") :: Sound),
})

AWP.Item = Item

return AWP