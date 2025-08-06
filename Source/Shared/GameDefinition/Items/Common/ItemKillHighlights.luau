local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.Shared.RoundRule.Types)

export type ItemKillHighlight = {
	Title: string,
	Description: string,
	Priority: number,
	Threshold: number,
}

local function ItemKillHighlights(...: ItemKillHighlight): Types.BeforeHitParticipant
	local highlightsArray = table.pack(...)

	table.sort(highlightsArray, function(highlight1, highlight2)
		return highlight1.Priority < highlight2.Priority --todo: i remember that something like this errored before, but i checked with lune and it didn't. see what's up, this might not work still.
	end)

	return function(item, round, victim, params)
		assert(item.Kind ~= "ExplosionParams")

		local attacker = params.Attacker
		if not attacker then
			return true
		end

		local willDie = params.Amount >= victim:GetHealth()
        if not willDie then
            return true
        end

		local identifier = "Highlights_KillsWithItem_" .. item.Definition.Name
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

return ItemKillHighlights