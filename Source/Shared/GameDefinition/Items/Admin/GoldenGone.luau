local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Ammo = require(ReplicatedStorage.API.Item.Ammo)
local Modify = require(ReplicatedStorage.API.Modify)
local GoldenGun = require(ReplicatedStorage.Shared.GameDefinition.Items.Guns.GoldenGun)

local GoldenGone = Modify(GoldenGun, "Golden Gone", {
	PrimaryInterval = 0,
    AmmoDefinition = Ammo["Super Gun"],
})

return table.freeze(GoldenGone)