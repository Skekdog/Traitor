local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local FaceIt = require(script.Parent.Parent.GameState.Face)
local FramedNotification = require(script.Parent.Parent.Interface.FramedNotification)
local Types = require(ReplicatedStorage.API.Types)
local GetRemote = require(ReplicatedStorage.Shared.GameDefinition.Items.Common.GetRemote)

local Targets = {}

local remote = GetRemote("AssignTarget")

function Targets.AssignTarget(participant: Types.Participant, target: Types.Participant): ()
	participant.Extras.FramedTarget = target
	target.Extras.FramedHunter = participant

	FramedNotification(participant, "💠 You have received a new target.")
	FramedNotification(target, "💠 You have a new hunter.")

	local targetChecker = participant:GetItems()["TargetChecker"]
	if targetChecker then
		local model = targetChecker.Model :: typeof(script.Parent.Parent.FramedItems.TargetChecker.TargetChecker)

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

		remote:FireClient(participant.Player, target.Player.Name)
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

if RunService:IsClient() then
	local name: string?
	local label: ImageLabel?

	local function set(): ()
		if not name or not label then
			return
		end

		local char = workspace.Characters:FindFirstChild(name)
		if not char or not char:IsA("Model") then
			return
		end

		local face = FaceIt.GetFaceInstance(char)
		if not face then
			return
		end

		label.Image = face.Texture
	end

	remote.OnClientEvent:Connect(function(newName: string)
		name = newName
		set()
	end)

	workspace.CurrentCamera.DescendantAdded:Connect(function(descendant)
		if descendant.Name == "ImageLabel" and descendant.Parent and descendant.Parent.Name == "TargetChecker" and descendant:IsA("ImageLabel") then
			label = descendant
			set()
		end
	end)
end

return Targets