local ReplicatedStorage = game:GetService("ReplicatedStorage")
local FramedNotification = require(script.Parent.FramedNotification)
local Types = require(ReplicatedStorage.API.Types)

local Targets = {}

function Targets.AssignTarget(participant: Types.Participant, target: Types.Participant): ()
	participant.Extras.FramedTarget = target
	target.Extras.FramedHunter = participant

	FramedNotification(participant, "💠 You have received a new target.")
	FramedNotification(target, "💠 You have a new hunter.")
end

function Targets.LoadFirstTargets(framed: {Types.Participant}): ()
	for i, participant in framed do
		Targets.AssignTarget(participant, framed[i % #framed + 1])
	end
end

return Targets