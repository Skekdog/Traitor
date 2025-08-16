local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local LocalCharacter = require(ReplicatedStorage.Shared.Character.LocalCharacter)
local ControlManager = require(ReplicatedStorage.Shared.Controls.ControlManager)
local Mouse = require(ReplicatedStorage.Shared.Interface.GameState.Mouse)
local ShowAlert = require(ReplicatedStorage.Shared.Interface.Util.ShowAlert)
local LocalParticipantInfo = require(ReplicatedStorage.Shared.LocalState.LocalParticipantInfo)
local LocalRoundInfo = require(ReplicatedStorage.Shared.LocalState.LocalRoundInfo)
local GetMapThingWithTag = require(ReplicatedStorage.Shared.RoundRule.Common.GetMapThingWithTag)
local GetPrimaryPart = require(ReplicatedStorage.Shared.RoundRule.Common.GetPrimaryPart)
local Types = require(ReplicatedStorage.Shared.RoundRule.Types)
local ClimbLadder = require(script.Parent.ClimbLadder)
local StandardDoor = require(script.Parent.StandardDoor)
local ViewCorpse = require(script.Parent.ViewCorpse)

local participant = LocalParticipantInfo.GetParticipant()

local module = {}

module.CorpseInteractDistance = 10

module.InteractTarget = nil :: Instance?

local function distanceCheck(target: Vector3, maxDistance: number): boolean
	local distance = Players.LocalPlayer:DistanceFromCharacter(target)
	return distance ~= 0 and distance <= maxDistance
end

local function interactCorpse(corpse: Model): boolean
	local status = participant.Status()
	if status == "Alive" then
		if not distanceCheck(corpse:GetPivot().Position, module.CorpseInteractDistance) then
			return false
		end
	end

	if corpse:GetAttribute("Burning") then
		ShowAlert("Ouch! This corpse is on fire!")
		return true
	end
	
	ViewCorpse(corpse)

	return true
end

local function interactDoor(door: BasePart): boolean
	if not distanceCheck(door.Position, 10) then
		return false
	end
	local request: StandardDoor.ClientInteraction = {
		Kind = "ClientInteraction" :: "ClientInteraction",
		Door = door,
	}
	StandardDoor(request)
	return true
end

local function interactInteractable(interactable: Types.Interactable): ()
	if interactable.Definition.OnInteractClient then
		interactable.Definition.OnInteractClient(interactable)
	end
	ReplicatedStorage.Remotes.ClientServer.InteractInteractable:FireServer(interactable.Object)
end

local function tryInteractInteractable(interactablePart: BasePart, input: InputObject?): boolean
	local interactable = LocalRoundInfo.Interactables()[interactablePart]
	if not interactable then
		return false
	end

	local definition = interactable.Definition

	if not distanceCheck(interactablePart.Position, definition.InteractionRange) then
		return false
	end

	if definition.IsContinuousInteraction then
		while input and input.UserInputState ~= Enum.UserInputState.End and distanceCheck(interactablePart.Position, definition.InteractionRange) and module.InteractTarget == interactablePart do
			interactInteractable(interactable)
			task.wait()
		end
	else
		if not input or input.UserInputState == Enum.UserInputState.End then
			interactInteractable(interactable)
		end
	end

	return true
end

local function tryClimbLadder(map: Types.Map): boolean
	local root = LocalCharacter.RootPart()
	if not root then
		return false
	end

	for _, v in root:GetTouchingParts() do
		if v:HasTag("Ladder") then
			ClimbLadder.Climb(v)
			return true
		end
	end

	return false
end

function module.TryInteract(target: Instance?, input: InputObject?): boolean
	local map = LocalRoundInfo.Map()
	if not map then
		return false
	end

	if not target then
		if input and input.UserInputState ~= Enum.UserInputState.End then
			return false
		end
		return tryClimbLadder(map)
	end

	local model = target:FindFirstAncestorOfClass("Model")
	if model and model:IsDescendantOf(workspace.Corpses) then
		return interactCorpse(model)
	end

	local char = LocalCharacter.Character()
	if not char then
		return false
	end

	if target:HasTag("Door") and target:IsA("Model") or target:IsA("BasePart") then
		if input and input.UserInputState ~= Enum.UserInputState.End then
			return false
		end
		return interactDoor(GetPrimaryPart(target))
	end

	if target:IsA("BasePart") and target:IsDescendantOf(map.Folder) then
		tryInteractInteractable(target, input)
	end

	return false
end

local function interactAction(action: string, state: Enum.UserInputState, input: InputObject?): Enum.ContextActionResult
	return if module.TryInteract(module.InteractTarget, input) then Enum.ContextActionResult.Sink else Enum.ContextActionResult.Pass
end

ControlManager.Register("Interact", interactAction, Enum.ContextActionPriority.High.Value + 1)

local params = RaycastParams.new()
params.IgnoreWater = true
params.FilterType = Enum.RaycastFilterType.Exclude
params.CollisionGroup = "MouseInfoRay"

RunService.PostSimulation:Connect(function()
	local camera = workspace.CurrentCamera
	local cameraSubject = camera.CameraSubject
	if cameraSubject and cameraSubject.Parent and cameraSubject:IsA("Humanoid") then
		params.FilterDescendantsInstances = {cameraSubject.Parent :: Model}
	end
	
    local result = workspace:Raycast(camera.CFrame.Position, camera.CFrame.LookVector * 10000, params)
	-- 10000 distance because we should still be able to see players. Corpses can be viewed from distance 10, so we include that as a check there.

	Mouse.Reset()

	module.InteractTarget = nil

	if not result then
		return
	end

	local target = result.Instance
	module.InteractTarget = target
	assert(target)

	local prop = GetMapThingWithTag(target, "Prop")

	if prop then
		if prop:HasTag("Item") or prop:HasTag("AmmoBox") then
			return Mouse.ShowItemHint(prop)
		elseif prop:HasTag("Interactable") then
			return Mouse.ShowInteractableHint(target)
		end
	end

	local char = target:FindFirstAncestorOfClass("Model")
	if not char then
		return
	end

	if char:IsDescendantOf(workspace.Corpses) then
		return Mouse.ShowCorpseHint(char)
	elseif char:IsDescendantOf(workspace.Characters) then
		return Mouse.ShowPlayerInfo(char)
	end
end)

return module