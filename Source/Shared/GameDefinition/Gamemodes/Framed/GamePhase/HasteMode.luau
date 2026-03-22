local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HighlightCharacter = require(script.Parent.Parent.GameState.HighlightCharacter)
local Types = require(ReplicatedStorage.API.Types)
local FramedNotification = require(script.Parent.Parent.Interface.FramedNotification)

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

	for _, participant in round:GetParticipants() do
		FramedNotification(participant, "⚠️ Police can now be killed!")
	end

	for _, participant in framedAlive do
		local char = participant:GetCharacter()
		if char then
			HighlightCharacter(char, true, "Kill", framedAlive)
		end
	end
end

return table.freeze(HasteMode)