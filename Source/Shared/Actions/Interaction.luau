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

module.InteractProp = nil :: Types.MapThing?
module.InteractPart = nil :: BasePart?

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

local function interactDoor(door: Types.MapThing): boolean
	if not distanceCheck(GetPrimaryPart(door).Position, 10) then
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
	print("servering")
	ReplicatedStorage.Remotes.ClientServer.InteractInteractable:FireServer(interactable.Model)
end

local function tryInteractInteractable(prop: Types.MapThing, part: BasePart, input: InputObject?): boolean
	local interactable = LocalRoundInfo.Interactables()[prop]
	if not interactable then
		return false
	end

	local definition = interactable.Definition

	if not distanceCheck(part.Position, definition.InteractionRange) then
		return false
	end

	if definition.IsContinuousInteraction then
		while input and input.UserInputState ~= Enum.UserInputState.End and distanceCheck(part.Position, definition.InteractionRange) and module.InteractProp == prop do
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

function module.TryInteract(prop: Types.MapThing?, part: BasePart?, input: InputObject?): boolean
	local map = LocalRoundInfo.Map()
	if not map then
		return false
	end

	if not prop or not part then
		if input and input.UserInputState ~= Enum.UserInputState.End then
			return false
		end
		return tryClimbLadder(map)
	end

	if prop:IsDescendantOf(workspace.Characters) and prop:HasTag("Corpse") then
		assert(prop:IsA("Model"), "Corpses must be Models")
		return interactCorpse(prop)
	end

	local char = LocalCharacter.Character()
	if not char then
		return false
	end

	if prop:HasTag("Door") then
		if input and input.UserInputState ~= Enum.UserInputState.End then
			return false
		end
		return interactDoor(prop)
	end

	if prop:HasTag("Interactable") then
		tryInteractInteractable(prop, part, input)
	end

	return false
end

local function interactAction(action: string, state: Enum.UserInputState, input: InputObject?): Enum.ContextActionResult
	return if module.TryInteract(module.InteractProp, module.InteractPart, input) then Enum.ContextActionResult.Sink else Enum.ContextActionResult.Pass
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

	module.InteractProp = nil
	module.InteractPart = nil

	if not result then
		return
	end

	local target = result.Instance

	local prop = GetMapThingWithTag(target, {"Prop", "Door"})

	if prop then
		module.InteractPart = target
		module.InteractProp = prop
		if prop:HasTag("Interactable") then
			print("ya")
			return Mouse.ShowInteractableHint(prop, target)
		elseif prop:HasTag("Item") or prop:HasTag("AmmoBox") then
			return Mouse.ShowItemHint(prop)
		end
	end

	local char = target:FindFirstAncestorOfClass("Model")
	if not char then
		return
	end

	module.InteractTarget = char

	if char:HasTag("Corpse") then
		return Mouse.ShowCorpseHint(char)
	elseif char:IsDescendantOf(workspace.Characters) then
		return Mouse.ShowPlayerInfo(char)
	end
end)

return module