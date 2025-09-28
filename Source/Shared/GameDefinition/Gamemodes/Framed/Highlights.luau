local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.API.Types)
local StandardHighlights = require(ReplicatedStorage.Shared.GameDefinition.Gamemodes.Common.StandardHighlights)

local Highlights = {}

local QUOTES = {
	Police = {
		"The situation is under control. All spies were captured!",
		"After the Police were sent in to a local party to stop a spy,\nit was discovered that EVERY partygoer was a spy.",
		"The Police successfully stopped the violence at a party this evening.",
		"The local Police force was able to control the situation.",
		"The Police caught several spies Red-Handed this evening.",
		"Thanks to the help of undercover cops, the Police cracked down\non several spies today.",
	},
	Framed = {
		"Many are considering that a local resident was only framed for his crimes.",
		"A local resident escaped from the Police today. His innocence is in question.",
		"After receiving a tip from an agent, the Police think a local 'spy' may only be Framed.",
		"'I never do nothing wrong, but I always get Framed', claims local resident.",
		"Upper-class resident escaped Police this evening at a dangerous party.",
	},
}

function Highlights.AddQuote(round: Types.Round): ()
	assert(round.VictoryData)

	local victor = round.VictoryData.Victor
	local role = if victor.Kind == "Role" then victor else victor:GetRole()

	round:AddHighlight({
		Title = "The News",
		Description = QUOTES[role.Definition.Name][math.random(#QUOTES[role.Definition.Name])],
		Group = "TheNews",
		Priority = math.huge,
	})
end

function Highlights.OnDeath(round: Types.Round, participant: Types.Participant): ()
	local corpse = participant.Corpse
	if not corpse then
		return
	end

	StandardHighlights.OnDeath(round, participant, nil)

	if not round.Extras.FirstBloodAwarded and corpse.Killer then
		round.Extras.FirstBloodAwarded = true
		round:AddHighlight({
			Title = "First Blood",
			Description = corpse.Killer:GetFormattedName() .. " was responsible for the first death of the round.",
			Priority = 1,
			Group = "First Blood",
		})
	end

	if participant:GetRole().Definition.Name == "Police" then
		participant.Extras.PoliceKills = (participant.Extras.PoliceKills or 0) + 1
		if participant.Extras.PoliceKills >= 3 then
			round:AddHighlight({
				Title = "I Am The Law",
				Description = participant:GetFormattedName() .. ` ended {participant.Extras.PoliceKills} lives of espionage today.`,
				Group = "PoliceKills",
				Priority = 2,
			})
		end
	elseif participant:GetRole().Definition.Name == "Undercover" then
		participant.Extras.UndercoverKills = (participant.Extras.UndercoverKills or 0) + 1
		if participant.Extras.UndercoverKills >= 3 then
			round:AddHighlight({
				Title = "Right Behind You",
				Description = participant:GetFormattedName() .. ` executed {participant.Extras.UndercoverKills} spies. All whilst pretending to be one themselves.`,
				Group = "UndercoverKills",
				Priority = 2,
			})
		end
	end

	if participant:GetRole().Definition.Name == "Framed" then
		participant.Extras.FramedKills = (participant.Extras.FramedKills or 0) + 1
		if participant.Extras.FramedKills >= 3 then
			round:AddHighlight({
				Title = "I'm Innocent I Swear",
				Description = participant:GetFormattedName() .. ` was merely framed for {participant.Extras.FramedKills} crimes.`,
				Group = "FramedKills",
				Priority = 2,
			})
		end
	end
end

return Highlights