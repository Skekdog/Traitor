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

	local highlightsParamsMap: {[number]: ItemKillHighlight} = {}
	for _, highlight in highlightsArray do
		highlightsParamsMap[highlight.Threshold] = highlight
	end

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

		local highlightParams = highlightsParamsMap[kills]
		if highlightParams then
			local highlight = {
				Title = highlightParams.Title,
				Description = highlightParams.Description:format(attacker:GetFormattedName(), kills),
				Priority = highlightParams.Priority
			}
			round:AddHighlight(highlight)
		end

		return true
	end
end

return ItemKillHighlights