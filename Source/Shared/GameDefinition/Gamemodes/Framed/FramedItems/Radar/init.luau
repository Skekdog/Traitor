local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Items = require(ReplicatedStorage.API.Items)
local HighlightCharacter = require(script.Parent.Parent.GameState.HighlightCharacter)
local Targets = require(script.Parent.Parent.GameState.Targets)

local Radar = {}

local Item = Items.CopyModify(Items.GetItem("Radar"), "Radar", {
	Description = "Reveals the location of your target.",
	CreditCost = 2,
	MaxStock = {__nil = true},

	HeartbeatClient = {__nil = true},

	OnEquipClient = function()
		if not Targets.ClientTarget then
			return
		end

		local char = workspace.Characters:FindFirstChild(Targets.ClientTarget)
		if not char or not char:IsA("Model") then
			return
		end

		HighlightCharacter(char, true, "Kill", nil :: any)
	end,
})

Radar.Item = Item

return Radar