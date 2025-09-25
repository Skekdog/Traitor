local ReplicatedStorage = game:GetService("ReplicatedStorage")
local FaceIt = require(script.Parent.FaceIt)
local FramedNotification = require(script.Parent.FramedNotification)
local Types = require(ReplicatedStorage.API.Types)

local Targets = {}

function Targets.AssignTarget(participant: Types.Participant, target: Types.Participant): ()
	participant.Extras.FramedTarget = target
	target.Extras.FramedHunter = participant

	FramedNotification(participant, "💠 You have received a new target.")
	FramedNotification(target, "💠 You have a new hunter.")

	local targetChecker = participant:GetItems()["TargetChecker"]
	if targetChecker then
		local model = targetChecker.Model :: typeof(script.Parent.FramedItems.TargetChecker.TargetChecker)

		local targetChar = target:GetCharacter()
		if not targetChar then
			return
		end

		local face = FaceIt.GetFaceInstance(targetChar)
		if not face then
			return
		end

		local head = targetChar:FindFirstChild("Head")
		if not head or not head:IsA("BasePart") then
			return
		end

		model.TargetChecker.ImageLabel.Image = face.Texture
		model.TargetChecker.ImageLabel.ImageColor3 = head.Color
	end
end

function Targets.GetTarget(participant: Types.Participant): Types.Participant?
	return participant.Extras.FramedTarget
end

function Targets.GetHunter(participant: Types.Participant): Types.Participant?
	return participant.Extras.FramedHunter
end

function Targets.OnDeath(participant: Types.Participant): ()
	local hunter: Types.Participant? = participant.Extras.FramedHunter
	if not hunter then
		return
	end

	local target: Types.Participant? = participant.Extras.FramedTarget
	if not target then
		return
	end

	Targets.AssignTarget(hunter, participant.Extras.FramedTarget)
end

function Targets.LoadFirstTargets(framed: {Types.Participant}): ()
	for i, participant in framed do
		Targets.AssignTarget(participant, framed[i % #framed + 1])
	end
end

return Targets