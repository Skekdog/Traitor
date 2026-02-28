local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Face = require(script.Parent.Face)
local GetRemote = require(ReplicatedStorage.API.GetRemote)
local FramedNotification = require(script.Parent.Parent.Interface.FramedNotification)
local Types = require(ReplicatedStorage.API.Types)

local Targets = {}

local remote = GetRemote("AssignTarget", script)

function Targets.AssignTarget(participant: Types.Participant, target: Types.Participant, noNotify: boolean?): ()
	participant.Extras.FramedTarget = target
	target.Extras.FramedHunter = participant

	if not noNotify then
		FramedNotification(participant, "💠 You have received a new target.")
		FramedNotification(target, "💠 You have a new hunter.")
	end

	local targetChecker = participant:GetItems()["TargetChecker"]
	if targetChecker then
		local model = targetChecker.Model :: typeof(ReplicatedStorage.Assets.Gamemode.Framed.Items.TargetChecker)

		local targetChar = target:GetCharacter()
		if not targetChar then
			return
		end

		local head = targetChar:FindFirstChild("Head")
		if not head or not head:IsA("BasePart") then
			return
		end

		local face = Face.GetInstance(head)
		if not face then
			return
		end

		remote:FireClient(participant.Player, target.Player.Name)
		model.TargetChecker.ImageLabel.Image = face.Image
		model.TargetChecker.ImageLabel.BackgroundColor3 = head.Color
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
		Targets.AssignTarget(participant, framed[i % #framed + 1], true)
	end
end

if RunService:IsClient() then
	local TargetsClient = require(script.Parent.TargetsClient)
	remote.OnClientEvent:Connect(function(newName: string)
		TargetsClient.Target = newName
		TargetsClient.HasIntel = false
		TargetsClient.Set()
	end)
end

return Targets