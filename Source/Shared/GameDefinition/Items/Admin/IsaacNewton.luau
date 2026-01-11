local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Modify = require(ReplicatedStorage.API.ItemPresets.Modify)
local NewtonLauncher = require(ReplicatedStorage.Shared.GameDefinition.Items.Guns.NewtonLauncher)

local IsaacNewton = Modify(NewtonLauncher.Item, "Isaac Newton", {
	PrimaryInterval = 0,
})

return IsaacNewton