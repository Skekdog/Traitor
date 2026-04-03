local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DNATraces = require(ReplicatedStorage.API.DNATraces)
local GameHooks = require(ReplicatedStorage.API.GameHooks)
local Types = require(ReplicatedStorage.API.Types)

GameHooks.OnItemDropped["DNATraces"] = function(round: Types.Round, participant: Types.Participant, item: Types.Item)
	if not item.Model then
		return
	end
	DNATraces.Add(item, participant, nil, item.IconContent or Content.fromAssetId(4795275417), item.Model)
end

return nil