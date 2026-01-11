local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.Shared.RoundRule.Types)

export type ItemKillHighlight = {
	Title: string,
	Description: string,
	Priority: number,
	Threshold: number,
}

local module = {}

function module.GetIdentifier(itemName: string): string
	return "Highlights_KillsWithItem_" .. itemName
end

local function ItemKillHighlights(...: ItemKillHighlight): Types.BeforeHitParticipant
	local highlightsArray = table.pack(...)
	highlightsArray.n = nil :: any

	table.sort(highlightsArray, function(highlight1, highlight2)
		return highlight1.Priority > highlight2.Priority --todo: i remember that something like this errored before, but i checked with lune and it didn't. see what's up, this might not work still.
	end)

	return function(item, params, victim)
		local attacker = params.Attacker
		if not attacker then
			return true
		end

		local round = attacker.Round

		if not round:IsInProgress() then
			return true
		end

		local willDie = params.Amount >= victim:GetHealth()
        if not willDie then
            return true
        end

		local identifier = module.GetIdentifier(item.Name)
		attacker.Extras[identifier] = (attacker.Extras[identifier] or 0) + 1

		local kills = attacker.Extras[identifier]

		local highlightParams: ItemKillHighlight?
		for _, v in highlightsArray do
			if kills >= v.Threshold then
				highlightParams = v
				break
			end
		end

		if highlightParams then
			local highlight = {
				Title = highlightParams.Title,
				Description = highlightParams.Description:format(attacker:GetFormattedName(), kills),
				Priority = highlightParams.Priority,
				Group = identifier,
			}
			round:AddHighlight(highlight)
		end

		return true
	end
end

setmetatable(module, {
	__call = function(self, ...: ItemKillHighlight): Types.BeforeHitParticipant
		return ItemKillHighlights(...)
	end
})

return module