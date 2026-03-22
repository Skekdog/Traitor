local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GetAliveRoles = require(script.Parent.Parent.Roles.GetAliveRoles)
local HighlightCharacter = require(script.Parent.HighlightCharacter)
local RedHanded = require(script.Parent.RedHanded)
local Types = require(ReplicatedStorage.API.Types)

local Mistakes = {}

local MISTAKE_SLAY_THRESHOLD = 1

function Mistakes.MistakeMade(participant: Types.Participant): ()
	local round = participant.Round

	participant.Extras.FramedMistakes = (participant.Extras.FramedMistakes or 0) + 1

	if participant.Extras.FramedMistakes == 1 then
		RedHanded.SetPermanent(participant)
		local char = participant:GetCharacter()
		if not char then
			return
		end

		local law = GetAliveRoles(round, {"Police", "Undercover"})
		HighlightCharacter(char, true, "Kill", law)
	end
end

function Mistakes.HasMadeMistake(participant: Types.Participant): boolean
	return (participant.Extras.FramedMistakes or 0) > 0
end

function Mistakes.TrySlayForMistakes(participant: Types.Participant): boolean
	if (participant.Extras.FramedMistakes or 0) >= MISTAKE_SLAY_THRESHOLD then
		participant:TryTakeDamage({
			Amount = math.huge,
			Source = "Other",
		})
		participant.Round:SendMessage(nil, `[PLAYER-{participant.Player.Name}] was slain for RDM.`, "All")
		return true
	end
	return false
end

return table.freeze(Mistakes)