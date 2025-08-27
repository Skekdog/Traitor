local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local GetPrimaryPart = require(ReplicatedStorage.Shared.RoundRule.Common.GetPrimaryPart)
local Types = require(ReplicatedStorage.Shared.RoundRule.Types)
local RoundHandler = require(ServerScriptService.RoundHandler)
local DynamicInteractable = require(ReplicatedStorage.Compat.DynamicInteractable)

local function distanceFromBox(origin: Vector3, size: Vector3, point: Vector3): number
	local minVec = origin - size / 2
	local maxVec = origin + size / 2
	local dx = math.max(minVec.X - point.X, 0, point.X - maxVec.X)
	local dy = math.max(minVec.Y - point.Y, 0, point.Y - maxVec.Y)
	local dz = math.max(minVec.Z - point.Z, 0, point.Z - maxVec.Z)
	return math.sqrt(dx * dx + dy * dy + dz * dz)
end

local function InteractInteractable(player: Player, interactablePart: unknown): ()
	if typeof(interactablePart) ~= "Instance" or (not interactablePart:IsA("BasePart") and not interactablePart:IsA("Model")) then
		return
	end
	local mapThing = interactablePart :: Types.MapThing

	if not player.Character then
		return
	end

	local round = RoundHandler.GetRound()
	local participant = round:GetParticipant(player.Name)

	if not participant or participant:GetStatus() ~= "Alive" then
		return
	end

	local interactable = round:GetInteractable(mapThing) or DynamicInteractable.TryCreateNewInteractable(mapThing)
	if not interactable then
		return
	end

	if not interactable.Definition.OnInteractServer then
		return
	end

	local size = if mapThing:IsA("BasePart") then mapThing.Size else mapThing:GetExtentsSize()
	local origin = GetPrimaryPart(mapThing).Position

	if distanceFromBox(origin, size, player.Character:GetPivot().Position) > interactable.Definition.InteractionRange * 1.1 then
		return print(origin)
	end

	interactable.Definition.OnInteractServer(interactable, participant)
end

ReplicatedStorage.Remotes.ClientServer.InteractInteractable.OnServerEvent:Connect(InteractInteractable)

return InteractInteractable