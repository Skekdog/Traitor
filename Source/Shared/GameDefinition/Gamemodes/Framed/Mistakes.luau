local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HighlightCharacter = require(script.Parent.HighlightCharacter)
local Types = require(ReplicatedStorage.API.Types)
local CombineTable = require(ReplicatedStorage.Shared.Util.CombineTable)

local Mistakes = {}

local MISTAKE_SLAY_THRESHOLD = 2

function Mistakes.MistakeMade(participant: Types.Participant): ()
	local round = participant.Round

	participant.Extras.FramedMistakes = (participant.Extras.FramedMistakes or 0) + 1

	if participant.Extras.FramedMistakes == 1 then
		local char = participant:GetCharacter()
		if not char then
			return
		end

		local law = CombineTable(round:GetParticipantsWithRole(round:GetRoleFromRoleName("Police")), round:GetParticipantsWithRole(round:GetRoleFromRoleName("Undercover")))
		HighlightCharacter(char, true, "Kill", law)
	end
end

function Mistakes.TrySlayForMistakes(participant: Types.Participant): ()
	if (participant.Extras.FramedMistakes or 0) >= MISTAKE_SLAY_THRESHOLD then
		participant:TryTakeDamage({
			Amount = math.huge,
			Source = "Other",
		})
		participant.Round:SendMessage(nil, `[PLAYER-{participant.Player.Name}] was slain for RDM.`, "All")
	end
end

return Mistakes