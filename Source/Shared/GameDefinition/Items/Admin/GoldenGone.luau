local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Ammo = require(ReplicatedStorage.API.ItemPresets.Ammo)
local Modify = require(ReplicatedStorage.API.ItemPresets.Modify)
local GoldenGun = require(ReplicatedStorage.Shared.GameDefinition.Items.Guns.GoldenGun)

local GoldenGone = Modify(GoldenGun, "Golden Gone", {
	PrimaryInterval = 0,
    AmmoDefinition = Ammo["Super Gun"],
})

return GoldenGone