local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Custom = require(ReplicatedStorage.API.Item.Presets.Custom)

local Speed = {}

local item = Custom({
	Name = "Speed",
	DisplayName = "Speed Boost",
	Description = "Provides a permanent speed boost.",
	IconContent = Content.fromAssetId(2724978350),

	Cost = 1,
	MaxStock = 1,

	OnEquipClient = function(): ()
		local WalkSpeed = require(ReplicatedStorage.Shared.Character.WalkSpeed)
		WalkSpeed.SetModifier("SpeedBoost", WalkSpeed.GetModifier("SpeedBoost") + 4)
	end,
})

Speed.Item = item

return table.freeze(Speed)