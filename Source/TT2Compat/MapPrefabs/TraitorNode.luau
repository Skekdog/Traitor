local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ActionNode = require(ReplicatedStorage.Shared.MapPrefabs.ActionNode)
local Types = require(ReplicatedStorage.API.Types)

local function TraitorNode(object: Script, tip: string, cost: number, interval: number, radius: number, callback: (Player) -> ()): ()
	local MapObject: Types.MapObject? = object:FindFirstAncestorWhichIsA("BasePart")
	if not MapObject then
		local model = object:FindFirstAncestorWhichIsA("Model")
		if model then
			MapObject = model
		end
	end

	if not MapObject then
		return
	end

	ActionNode({
		Adornee = MapObject,
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