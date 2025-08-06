local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.Shared.RoundRule.Types)

local module = {}

local function addHighlight(round: Types.Round, highlightParams: Types.Highlight, participant: Types.Participant): ()
	local highlight = {
		Title = highlightParams.Title,
		Description = highlightParams.Description:format(participant:GetFormattedName()),
		Priority = highlightParams.Priority,
	}
	round:AddHighlight(highlight)
end

local suicideHighlight = {
	Title = "Lonely and Depressed",
	Description = "%s was the only one who killed themselves.",
	Priority = 1,
}

local suicideCultHighlight = {
	Title = "Suicide Cult Leader",
	Description = "%s showed the other suiciders how to do it by being the first to go.",
	Priority = 2,
}

local SUICIDE_CULT_THRESHOLD = 3

module.OnDeath = function(_, victim)
	local round = victim.Round
	local corpse = victim.Corpse
	if corpse then
		local attacker = corpse.Killer
		if attacker == victim then
			if not round.Extras.SuicideCount then
				addHighlight(round, suicideHighlight, victim)
				round.Extras.SuicideCount = 1
				round.Extras.FirstSuicide = victim
			else
				round.Extras.SuicideCount += 1
				if round.Extras.SuicideCount == SUICIDE_CULT_THRESHOLD then
					addHighlight(round, suicideCultHighlight, round.Extras.FirstSuicide)
				end
			end
		end
	end
end :: typeof((({} :: any) :: Types.Gamemode).OnDeath)

return module