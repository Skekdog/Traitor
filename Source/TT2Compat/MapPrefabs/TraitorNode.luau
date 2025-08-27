local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ActionNode = require(ReplicatedStorage.Shared.MapPrefabs.ActionNode)
local Types = require(ReplicatedStorage.Shared.RoundRule.Types)

local function TraitorNode(object: Script, tip: string, cost: number, interval: number, radius: number, callback: (Player) -> ()): ()
	local mapThing: Types.MapThing? = object:FindFirstAncestorWhichIsA("BasePart")
	if not mapThing then
		local model = object:FindFirstAncestorWhichIsA("Model")
		if model then
			mapThing = model
		end
	end

	if not mapThing then
		return
	end

	ActionNode({
		Adornee = mapThing,
		Title = tip,
		Cost = cost,
		Cooldown = interval,
		Radius = radius,
		Action = function(participant)
			return callback(participant.Player)
		end
	})
end

return TraitorNode