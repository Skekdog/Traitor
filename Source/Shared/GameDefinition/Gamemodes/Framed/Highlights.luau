local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StandardGame = require(ReplicatedStorage.API.StandardGame)
local Types = require(ReplicatedStorage.API.Types)

local Highlights = {}

local function format(text: string, role: "Police" | "Framed" | "Undercover"): string
	local colour = if role == "Police" then Color3.fromRGB(16, 108, 172) elseif role == "Framed" then Color3.fromRGB(200, 44, 28) else Color3.fromRGB(40, 140, 36)
	return `<font color='#{colour:ToHex()}'>{text}</font>`
end

local QUOTES = {
	Police = {
		`The situation is under control. All spies were captured!`,
		`After the {format("Police", "Police")} were sent in to a local party to stop a spy,\nit was discovered that EVERY partygoer was a spy.`,
		`The {format("Police", "Police")} successfully stopped the violence at a party this evening.`,
		`The local {format("Police", "Police")} force was able to control the situation.`,
		`The {format("Police", "Police")} caught several spies red-handed this evening.`,
		`Thanks to the help of {format("Undercover", "Undercover")} cops, the {format("Police", "Police")} cracked down\non several spies today.`,
	},

	Framed = {
		`Many are considering that a local resident was only {format("Framed", "Framed")} for his crimes.`,
		`A local resident escaped from the {format("Police", "Police")} today. His innocence is in question.`,
		`After receiving a tip from an agent, the {format("Police", "Police")} think a local spy may only be {format("Framed", "Framed")}.`,
		`"I never do nothing wrong, but I always get {format("Framed", "Framed")}," claims local resident.`,
		`Upper-class resident escaped {format("Police", "Police")} this evening at a dangerous party.`,
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

	StandardGame.Highlights.OnDeath(round, participant)

	if not round.Extras.FirstBloodAwarded and corpse.Killer and corpse.Killer ~= participant then
		round.Extras.FirstBloodAwarded = true
		round:AddHighlight({
			Title = "First Blood",
			Description = corpse.Killer:GetFormattedName() .. " was responsible for the first death of the round.",
			Priority = 1,
			Group = "First Blood",
			ScoreBonus = 2,
			Participants = {corpse.Killer},
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
				ScoreBonus = 2,
				Participants = {participant},
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
				ScoreBonus = 2,
				Participants = {participant},
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
				ScoreBonus = 2,
				Participants = {participant},
			})
		end
	end
end

return Highlights