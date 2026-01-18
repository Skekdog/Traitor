local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Ammo = require(ReplicatedStorage.API.Item.Ammo)
local Modify = require(ReplicatedStorage.API.Modify)
local XM1014 = require(ReplicatedStorage.Shared.GameDefinition.Items.Guns.XM1014)

local SuperShotgun = Modify(XM1014, "Super Shotgun", {
	PrimaryInterval = 0,
    AmmoDefinition = Ammo["Super Gun"],
})

return SuperShotgun