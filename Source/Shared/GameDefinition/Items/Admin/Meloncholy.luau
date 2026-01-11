local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Ammo = require(ReplicatedStorage.API.ItemPresets.Ammo)
local Modify = require(ReplicatedStorage.API.ItemPresets.Modify)
local MelonLauncher = require(ReplicatedStorage.Shared.GameDefinition.Items.Guns.MelonLauncher)

local Meloncholy = Modify(MelonLauncher.Item, "Meloncholy", {
	DisplayName = "Meloncholy",
    AmmoDefinition = Ammo.Infinite,
    AttackInterval = 0.5,
})

return Meloncholy