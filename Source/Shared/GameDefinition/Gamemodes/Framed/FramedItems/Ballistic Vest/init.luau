local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Modify = require(ReplicatedStorage.API.Modify)
local Items = require(ReplicatedStorage.API.StandardGame)
local Types = require(ReplicatedStorage.API.Types)

local BallisticVest = {}

local Item = Modify(Items.GetItem("Ballistic Vest"), "Ballistic Vest", {
	Cost = 2,
	Description = "Increases health by 100. Visible to others.",
	OnEquipServer = function(_, participant: Types.Participant): ()
		local hum = participant:GetHumanoid()
		if not hum then
			return
		end

		hum.MaxHealth += 100
		hum.Health = math.min(hum.Health + 100, hum.MaxHealth)
		hum:AddAccessory(ReplicatedStorage.Assets.Gamemode.Framed.Items["Ballistic Vest"]:Clone())
	end
})

BallisticVest.Item = Item

return BallisticVest