local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local InstanceSignal = require(ReplicatedStorage.Shared.Util.InstanceSignal)

local PreferredInput = {}

PreferredInput.PreferredInput = InstanceSignal.ListenProperty<<Enum.PreferredInput>>(UserInputService, "PreferredInput")

return table.freeze(PreferredInput)