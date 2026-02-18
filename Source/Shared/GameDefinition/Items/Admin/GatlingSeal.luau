local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Ammo = require(ReplicatedStorage.API.Item.Ammo)
local Modify = require(ReplicatedStorage.API.Modify)
local SealGun = require(ReplicatedStorage.Shared.GameDefinition.Items.Guns.SealGun)

local GatlingSeal = Modify(SealGun.Item, "Gatling Seal", {
	PrimaryInterval = 0.25,
	ProjectileSpeed = 200,
	Damage = 0,
    AmmoDefinition = Ammo["Super Gun"],
})

return GatlingSeal