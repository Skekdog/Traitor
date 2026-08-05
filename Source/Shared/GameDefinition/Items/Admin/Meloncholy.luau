local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Ammo = require(ReplicatedStorage.API.Item.Ammo)
local Modify = require(ReplicatedStorage.API.Modify)
local MelonLauncher = require(ReplicatedStorage.Shared.GameDefinition.Items.Guns.MelonLauncher)

local Meloncholy = Modify(MelonLauncher.Item, "Meloncholy", {
	DisplayName = "Meloncholy",
    AmmoDefinition = Ammo.Infinite,
    AttackInterval = 0.1,
})

return table.freeze(Meloncholy)