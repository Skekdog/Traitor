local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ActionNodeClient = require(script.Parent.ActionNodeClient)
local LocalCharacter = require(ReplicatedStorage.Shared.Character.LocalCharacter)
local ControlManager = require(ReplicatedStorage.Shared.Controls.ControlManager)
local Mouse = require(ReplicatedStorage.Shared.Interface.GameState.Mouse)
local ShowAlert = require(ReplicatedStorage.Shared.Interface.Util.ShowAlert)
local LocalParticipantInfo = require(ReplicatedStorage.Shared.LocalState.LocalParticipantInfo)
local LocalRoundInfo = require(ReplicatedStorage.Shared.LocalState.LocalRoundInfo)
local GetMapObjectWithTag = require(ReplicatedStorage.Shared.RoundRule.Common.GetMapObjectWithTag)
local Types = require(ReplicatedStorage.Shared.RoundRule.Types)
local ClimbLadder = require(script.Parent.ClimbLadder)
local PossessProp = require(script.Parent.PossessProp)
local ViewCorpse = require(script.Parent.ViewCorpse)

local participant = LocalParticipantInfo.GetParticipant()

local module = {}

module.LastId = {
	Id = nil :: Model?,
	At = 0,
}

module.InteractProp = nil :: Types.MapObject?
module.InteractPart = nil :: BasePart?
module.ActionNode = nil :: ActionNodeClient.ClientNodeData?

local function distanceCheck(target: Vector3, maxDistance: number): boolean
	local distance = Players.LocalPlayer:DistanceFromCharacter(target)
	return distance ~= 0 and distance <= maxDistance
end

local function interactCorpse(corpse: Model): boolean
	local status = participant.Status()
	if status == "Alive" then
		if not distanceCheck(corpse:GetPivot().Position, Mouse.CorpseInteractDistance) then
			return false
		end
	end

	if corpse:HasTag("Burning") then
		ShowAlert("Ouch! This corpse is on fire!")
		return true
	end

	ViewCorpse(corpse)

	return true
end

local function interactInteractable(prop: Types.Prop): ()
	local interactable = prop.Interactable
	if interactable and interactable.OnInteractClient then
		interactable.OnInteractClient(prop)
	end
	ReplicatedStorage.Remotes.ClientServer.InteractInteractable:FireServer(prop.Model)
end

local function tryInteractInteractable(mapObject: Types.MapObject, part: BasePart, input: InputObject?): boolean
	local prop = LocalRoundInfo.Interactables()[mapObject]
	if not prop or not prop.Interactable then
		return false
	end

	local definition = prop.Interactable

	if not distanceCheck(part.Position, definition.InteractionRange) then
		return false
	end

	if definition.IsContinuousInteraction then
		while input and input.UserInputState ~= Enum.UserInputState.End and distanceCheck(part.Position, definition.InteractionRange) and module.InteractProp == mapObject do
			interactInteractable(prop)
			task.wait()
		end
	else
		if not input or input.UserInputState == Enum.UserInputState.End then
			interactInteractable(prop)
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

function module.TryInteract(prop: Types.MapObject?, part: BasePart?, input: InputObject?, actionNode: ActionNodeClient.ClientNodeData?): boolean
	local map = LocalRoundInfo.Map()
	if not map then
		return false
	end

	if not prop or not part then
		if input and input.UserInputState ~= Enum.UserInputState.End then
			return false
		end

		if actionNode then
			ActionNodeClient.Activate(actionNode)
			return true
		end

		return tryClimbLadder(map)
	end

	if prop:IsDescendantOf(workspace.Characters) and prop:HasTag("Corpse") then
		assert(prop:IsA("Model"), "Corpses must be Models")
		return interactCorpse(prop)
	end

	if not prop:HasTag("Interactable") and LocalParticipantInfo.GetParticipant().Status() ~= "Alive" then
		PossessProp.TryPossess(part)
	end

	local char = LocalCharacter.Character()
	if not char then
		return false
	end

	if prop:HasTag("Interactable") then
		tryInteractInteractable(prop, part, input)
	end

	return false
end

local function interactAction(action: string, state: Enum.UserInputState, input: InputObject?): Enum.ContextActionResult
	return if module.TryInteract(module.InteractProp, module.InteractPart, input, module.ActionNode) then Enum.ContextActionResult.Pass else Enum.ContextActionResult.Pass
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
	else
		params.FilterDescendantsInstances = {}
	end

	Mouse.Reset()

	module.ActionNode = nil
	module.InteractProp = nil
	module.InteractPart = nil

	local activeNode = ActionNodeClient.GetActiveNode()
	if activeNode then
		module.ActionNode = activeNode
		return
	end

    local result = workspace:Raycast(camera.CFrame.Position, camera.CFrame.LookVector * 10000, params)
	-- 10000 distance because we should still be able to see players. Corpses can be viewed from distance 10, so we include that as a check there.

	if not result then
		return
	end

	local target = result.Instance

	local prop = GetMapObjectWithTag(target, {"Prop", "Door"})

	if prop then
		module.InteractPart = target
		module.InteractProp = prop
		local ret = false
		if prop:HasTag("Item") or prop:HasTag("AmmoBox") then
			Mouse.ShowItemHint(prop)
			ret = true
		end
		if prop:HasTag("Interactable") or (LocalParticipantInfo.GetParticipant().Status() ~= "Alive" and not PossessProp.IsPossessed(prop) and not prop:HasTag("Corpse")) then
			Mouse.ShowInteractableHint(prop, target)
			ret = true
		end
		if ret then
			return
		end
	end

	local char = target:FindFirstAncestorOfClass("Model")
	if not char then
		return
	end

	module.InteractTarget = char

	if char:HasTag("Corpse") then
		module.LastId = {
			Id = char,
			At = os.clock(),
		}
		return Mouse.ShowCorpseHint(char)
	elseif char:IsDescendantOf(workspace.Characters) then
		module.LastId = {
			Id = char,
			At = os.clock(),
		}
		return Mouse.ShowPlayerInfo(char)
	end
end)

return module