local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GetAliveRoles = require(script.Parent.GetAliveRoles)
local HighlightCharacter = require(script.Parent.HighlightCharacter)
local Types = require(ReplicatedStorage.API.Types)

local RedHanded = {}

local RED_HANDED_DURATION = 5

function RedHanded.Start(participant: Types.Participant): ()
	local id = GetAliveRoles(participant.Round, {"Police", "Undercover", "Framed"})

	local char = participant:GetCharacter()
	if char then
		HighlightCharacter(char, true, "RedHanded", id)
	end

	participant.Extras.FramedRedHanded = id
end

function RedHanded.Stop(participant: Types.Participant): ()
	local id = participant.Extras.FramedRedHanded
	if not id then
		return
	end

	task.delay(RED_HANDED_DURATION, function()
		if participant.Extras.FramedRedHanded ~= id then
			return
		end

		id = participant.Extras.FramedRedHanded
		participant.Extras.FramedRedHanded = nil

		local char = participant:GetCharacter()
		if char then
			HighlightCharacter(char, false, "RedHanded", id)
		end
	end)
end

return RedHanded