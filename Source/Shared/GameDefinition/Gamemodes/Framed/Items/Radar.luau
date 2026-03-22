local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Modify = require(ReplicatedStorage.API.Modify)
local Items = require(ReplicatedStorage.API.StandardGame)
local HighlightCharacter = require(script.Parent.Parent.GameState.HighlightCharacter)

local Radar = {}

local Item = Modify(Items.GetItem("Radar"), "Radar", {
	Description = "Reveals the location of your target.",
	Cost = 2,
	MaxStock = {__nil = true},

	DoNotShowInEquipmentList = true,

	HeartbeatClient = {__nil = true},

	OnEquipClient = function()
		local TargetsClient = require(script.Parent.Parent.GameState.TargetsClient)

		local target = TargetsClient.GetCurrentTarget()
		if not target then
			return
		end

		local char = workspace.Characters:FindFirstChild(target)
		if not char or not char:IsA("Model") then
			return
		end

		HighlightCharacter(char, true, "Kill", nil :: any)
	end,
})

Radar.Item = Item

return table.freeze(Radar)