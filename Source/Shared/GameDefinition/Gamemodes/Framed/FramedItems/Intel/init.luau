local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.API.Types)

local Intel = {}

local function OnEquipClient(): ()
	local TargetsClient = require(script.Parent.Parent.GameState.TargetsClient)
	TargetsClient.HasIntel = true
	TargetsClient.Set()
end

local Item: Types.ItemDefinition = {
	Kind = "Item" :: "Item",

	Name = "Intel",
	Description = "Reveals your target's identity.",
	Icon = "rbxassetid://7129850222",

	CreditCost = 1,

	OnEquipClient = OnEquipClient,
}

Intel.Item = Item

return Intel