local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.Shared.RoundRule.Types)

local module = {}

local function addHighlight(round: Types.Round, highlightParams: Types.Highlight, participant: Types.Participant, ...): ()
	local highlight = {
		Title = highlightParams.Title,
		Description = highlightParams.Description:format(participant:GetFormattedName(), ...),
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

local fieldResearchHighlight = {
	Title = "Field Research",
	Description = "%s tested their own resistance to explosions. It was not high enough.",
	Priority = 1,
}

local explosivesResearchGrantHighlight = {
	Title = "Explosives Research Grant",
	Description = "%s was recognized for their research on explosions. %d test subjects helped out.",
	Priority = 2,
}

local pushKillHighlight = {
	Title = "No Mr. Bond, I Expect You To Fall",
	Description = "%s pushed someone off a great height.",
	Priority = 2,
}

local fellHighlight = {
	Title = "Floored",
	Description = "%s let their body hit the floor after falling from a significant altitude.",
	Priority = 1,
}

local headshots1 = {
	Title = "Efficiency",
	Description = "%s discovered the joy of headshots and made %d.",
	Priority = 1,
}

local headshots2 = {
	Title = "Neurology",
	Description = "%s removed the brains from %d heads for a closer examination.",
	Priority = 3,
}

local headshots3 = {
	Title = "Videogames Made Me Do It",
	Description = "%s applied their murder simulation training and headshotted %d foes.",
	Priority = 5,
}

local iHateThisGame = {
	Title = "I Hate This Game",
	Description = "%s died right after the start of the round.",
	Priority = 1,
}

local pyrrhicVictory = {
	Title = "Pyrrhic Victory",
	Description = "%s died only seconds before their team won the round.",
	Priority = 1,
}

local HATE_THRESHOLD = 1
local PYRRHIC_THRESHOLD = 1

local HEADSHOTS_1_THRESHOLD = 2
local HEADSHOTS_2_THRESHOLD = 5
local HEADSHOTS_3_THRESHOLD = 8

local GRANT_THRESHOLD = 2

local SUICIDE_CULT_THRESHOLD = 3

module.OnDeath = function(_, victim)
	local round = victim.Round
	local corpse = victim.Corpse
	if not corpse then
		return
	end

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

	if corpse.CorpseView.DamageSource == "Explode" then
		if attacker == victim then
			addHighlight(round, fieldResearchHighlight, victim)
		elseif attacker then
			attacker.Extras.ExplosiveKills = (attacker.Extras.ExplosiveKills or 0) + 1
			if attacker.Extras.ExplosiveKills == GRANT_THRESHOLD then
				addHighlight(round, explosivesResearchGrantHighlight, attacker, attacker.Extras.ExplosiveKills)
			end
		end
	end

	if corpse.CorpseView.DamageSource == "Fall" then
		if attacker and attacker ~= victim then
			addHighlight(round, pushKillHighlight, attacker)
		elseif not attacker then
			addHighlight(round, fellHighlight, victim)
		end
	end

	if corpse.CorpseView.WasHeadshot and attacker then
		attacker.Extras.HeadshotKills = (attacker.Extras.HeadshotKills or 0) + 1
		local kills = attacker.Extras.HeadshotKills
		if kills == HEADSHOTS_1_THRESHOLD then
			addHighlight(round, headshots1, attacker, kills)
		elseif kills == HEADSHOTS_2_THRESHOLD then
			addHighlight(round, headshots2, attacker, kills)
		elseif kills == HEADSHOTS_3_THRESHOLD then
			addHighlight(round, headshots3, attacker, kills)
		end
	end

	if round.ElapsedPhaseTime < HATE_THRESHOLD then
		addHighlight(round, iHateThisGame, victim)
	end

	task.delay(PYRRHIC_THRESHOLD, function()
		if round:IsPostGame() then
			addHighlight(round, pyrrhicVictory, victim)
		end
	end)
end :: typeof((({} :: any) :: Types.Gamemode).OnDeath)

return module