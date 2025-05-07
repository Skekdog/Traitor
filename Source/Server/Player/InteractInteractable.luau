local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RoundHandler = require(ServerScriptService.RoundHandler)

local function InteractInteractable(player: Player, interactablePart: unknown): ()
	if typeof(interactablePart) ~= "Instance" or not interactablePart:IsA("BasePart") then
		return
	end

	local round = RoundHandler.GetRound()
	local participant = round:GetParticipant(player.Name)

	if not participant or participant:GetStatus() ~= "Alive" then
		return
	end

	local interactable = round:GetInteractable(interactablePart)
	if not interactable then
		return
	end

	if not interactable.Definition.OnInteractServer then
		return
	end

	if player:DistanceFromCharacter(interactablePart.Position) > interactable.Definition.InteractionRange * 1.1 then
		return
	end

	interactable.Definition.OnInteractServer(interactable, participant)
end

ReplicatedStorage.Remotes.ClientServer.InteractInteractable.OnServerEvent:Connect(InteractInteractable)

return InteractInteractable