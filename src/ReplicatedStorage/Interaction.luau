local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ClimbLadder = require(script.Parent.ClimbLadder)
local Types = require(ReplicatedStorage.RoundRule.Types)
local ControlManager = require(script.Parent.ControlManager)
local LocalCharacter = require(script.Parent.LocalCharacter)
local LocalRoundInfo = require(script.Parent.LocalRoundInfo)
local Mouse = require(script.Parent.Mouse)
local ShowAlert = require(script.Parent.ShowAlert)
local StandardDoor = require(script.Parent.StandardDoor)
local ViewCorpse = require(script.Parent.ViewCorpse)

local module = {}

module.InteractTarget = nil :: Instance?

local function distanceCheck(target: Vector3, maxDistance: number): boolean
	local distance = Players.LocalPlayer:DistanceFromCharacter(target)
	return distance ~= 0 and distance <= maxDistance
end

local function interactCorpse(corpse: Model): boolean
	local statusValue = LocalRoundInfo.PlayerStatuses()[Players.LocalPlayer.Name]
	if (if statusValue then statusValue() else "Spectating") == "Alive" then
		if not distanceCheck(corpse:GetPivot().Position, 10) then
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
	ReplicatedStorage.ClientServer.InteractInteractable:FireServer(interactable.Object)
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
		while input and input.UserInputState ~= Enum.UserInputState.End and distanceCheck(interactablePart.Position, definition.InteractionRange) do
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
		if v.Name == "Ladder" and v:IsDescendantOf(map.Bounds) then
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

	if target:IsA("BasePart") and target.Parent and target.Parent.Name == "Doors" and target:IsDescendantOf(map.DynamicMap) then
		if input and input.UserInputState ~= Enum.UserInputState.End then
			return false
		end
		return interactDoor(target)
	end

	if target:IsA("BasePart") and target:IsDescendantOf(map.Interactables) then
		tryInteractInteractable(target, input)
	end
	
	return false
end

ControlManager.Register("Interact", function(action, state, input)
	return if module.TryInteract(module.InteractTarget, input) then Enum.ContextActionResult.Sink else Enum.ContextActionResult.Pass
end, Enum.ContextActionPriority.High.Value + 1)

local params = RaycastParams.new()
params.IgnoreWater = true
params.FilterType = Enum.RaycastFilterType.Exclude
params.CollisionGroup = "MouseInfoRay"

RunService.PostSimulation:Connect(function()
	local camera = workspace.CurrentCamera
	local cameraSubject = camera.CameraSubject
	if cameraSubject and cameraSubject.Parent and cameraSubject:IsA("Humanoid") then
		params:AddToFilter(cameraSubject.Parent)
	end
	
    local result = workspace:Raycast(camera.CFrame.Position, camera.CFrame.LookVector * 10000, params)
	-- 10000 distance because we should still be able to see players. Corpses can be viewed from distance 10, so we include that as a check there.

	Mouse.Reset()

	local validAncestors = {workspace.Characters :: Folder, workspace.Corpses}
	local map = LocalRoundInfo.Map()
	if map then
		table.insert(validAncestors, map.ItemSpawns)
		table.insert(validAncestors, map.AmmoSpawns)
		table.insert(validAncestors, map.Interactables)
		table.insert(validAncestors, map.DynamicMap)
	end

	module.InteractTarget = nil

	if not result then
		return
	end
	
	local isValid = false
	for _, v in validAncestors do
		if result.Instance:IsDescendantOf(v) then
			isValid = true
		end
	end

	if not isValid then
		return
	end

	module.InteractTarget = result.Instance
	assert(module.InteractTarget)

	if map then
		if module.InteractTarget:IsDescendantOf(map.ItemSpawns) or module.InteractTarget:IsDescendantOf(map.AmmoSpawns) then
			return Mouse.ShowItemHint(module.InteractTarget)
		elseif module.InteractTarget:IsDescendantOf(map.Interactables) then
			return Mouse.ShowInteractableHint(module.InteractTarget :: BasePart)
		end
	end

	local char = module.InteractTarget:FindFirstAncestorOfClass("Model")
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