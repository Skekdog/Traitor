local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HighlightCharacter = require(script.Parent.HighlightCharacter)
local Types = require(ReplicatedStorage.API.Types)

local HasteMode = {}

function HasteMode.IsHasteMode(round: Types.Round): boolean
	return round.Extras.FramedHasteMode == true
end

function HasteMode.Start(round: Types.Round): ()
	if HasteMode.IsHasteMode(round) then
		return
	end
	round.Extras.FramedHasteMode = true

	local framedAlive: {Types.Participant} = {}
	for _, v in round:GetParticipantsWithRole(round:GetRoleFromRoleName("Framed")) do
		if v:IsAlive() then
			table.insert(framedAlive, v)
		end
	end

	for _, participant in framedAlive do
		local char = participant:GetCharacter()
		if char then
			HighlightCharacter(char, true, "Kill", framedAlive)
		end
	end
end

return HasteMode