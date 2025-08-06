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

local burn1 = {
	Title = "Like Grandma Used To Make Them",
	Description = "%s fried several people to a nice crisp.",
	Priority = 2,
}

local burn2 = {
	Title = "Pyroid",
	Description = "%s was heard cackling loudly after burning one of their many victims.",
	Priority = 4,
}

local burn3 = {
	Title = "Pyrrhic Burnery",
	Description = "%s burned them all, but is now all out of incendiary grenades! How will they cope!?",
	Priority = 5,
}

local drown = {
	Title = "Fish In Water",
	Description = "%s thought they would say hello to the fish, but didn't plan their way out.",
	Priority = 1
}

local bodies1 = {
	Title = "Coroner",
	Description = "%s found %d bodies lying around.",
	Priority = 1,
}

local bodies2 = {
	Title = "Gotta Catch Em All",
	Description = "%s found %d corpses for their collection.",
	Priority = 2,
}

local bodies3 = {
	Title = "Death Scent",
	Description = "%s keeps stumbling on random corpses, %d times this round.",
	Priority = 3,
}

local moron = {
	Title = "Moron",
	Description = "%s couldn't figure out which side they were on, and killed over half of their comrades.",
	Priority = 5,
}

local roleplayer = {
	Title = "Roleplayer",
	Description = "%s was roleplaying a madman, honest. That's why they killed most of their team.",
	Priority = 3,
} -- 4 kills

local teamkiller = {
	Title = "Teamkiller",
	Description = "%s murdered the entirety of their team. OMGBANBANBAN.",
	Priority = 6,
}

local oopsie = {
	Title = "Made An Oopsie",
	Description = "%s had their finger slip just when they were aiming at a buddy.",
	Priority = 1,
}

local doubleOops = {
	Title = "Double-Oops",
	Description = "%s thought they got the enemy twice, but was wrong both times.",
	Priority = 2,
}

local karmaConscious = {
	Title = "Karma-conscious",
	Description = "%s couldn't stop after killing two teammates. Three is their lucky number.",
	Priority = 3,
}

local redneck = {
	Title = "Redneck",
	Description = "%s protected their turf real good by killing over a quarter of their teammates.",
	Priority = 4,
}

local MORON_MINIMUM_KILLS = 2
local REDNECK_MINIMUM_KILLS = 2
local TEAMKILLER_MINIMUM_KILLS = 2

local BODIES_1_THRESHOLD = 2
local BODIES_2_THRESHOLD = 5
local BODIES_3_THRESHOLD = 8

local BURN_1_THRESHOLD = 2
local BURN_2_THRESHOLD = 4
local BURN_3_THRESHOLD = 6

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

	if corpse.CorpseView.DamageSource == "Burn" and attacker then
		attacker.Extras.BurnKills = (attacker.Extras.BurnKills or 0) + 1
		local kills = attacker.Extras.BurnKills

		if kills == BURN_1_THRESHOLD then
			addHighlight(round, burn1, attacker)
		elseif kills == BURN_2_THRESHOLD then
			addHighlight(round, burn2, attacker)
		elseif kills == BURN_3_THRESHOLD then
			addHighlight(round, burn3, attacker)
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

	if not corpse.WasCorrectKill and attacker and attacker ~= victim then
		attacker.Extras.BadKills = (attacker.Extras.BadKills or 0) + 1
		local kills = attacker.Extras.BadKills

		local totalTeammates = 0

		local allies: {string} = attacker:GetRole().Definition.Allies or {}
		for _, roleName in allies do
			for _, participant in round:GetParticipantsWithRole(round:GetRoleFromRoleName(roleName)) do
				totalTeammates += 1
			end
		end

		local killPercent = kills / totalTeammates
		if kills >= TEAMKILLER_MINIMUM_KILLS and killPercent == 1 then
			addHighlight(round, teamkiller, attacker)
		elseif kills >= MORON_MINIMUM_KILLS and killPercent >= 0.5 then
			addHighlight(round, moron, attacker)
		elseif kills >= REDNECK_MINIMUM_KILLS and killPercent >= 0.25 then
			addHighlight(round, redneck, attacker)
		elseif kills == 1 then
			addHighlight(round, oopsie, attacker)
		elseif kills == 2 then
			addHighlight(round, doubleOops, attacker)
		elseif kills == 3 then
			addHighlight(round, karmaConscious, attacker)
		elseif kills == 4 then
			addHighlight(round, roleplayer, attacker)
		end
	end

	if corpse.CorpseView.DamageSource == "Drown" then
		addHighlight(round, drown, victim)
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

module.OnIdentifyCorpse = function(gamemode: Types.Gamemode, corpse: Types.Corpse, searcher: Types.Participant)
	local round = searcher.Round

	searcher.Extras.IdentifiedBodies = (searcher.Extras.IdentifiedBodies or 0) + 1
	local bodies = searcher.Extras.IdentifiedBodies

	if bodies == BODIES_1_THRESHOLD then
		addHighlight(round, bodies1, searcher)
	elseif bodies == BODIES_2_THRESHOLD then
		addHighlight(round, bodies2, searcher)
	elseif bodies == BODIES_3_THRESHOLD then
		addHighlight(round, bodies3, searcher)
	end
end

return module