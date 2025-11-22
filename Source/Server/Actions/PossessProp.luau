local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RoundHandler = require(ServerScriptService.RoundHandler)
local GetParticipant = require(ReplicatedStorage.API.GetParticipant)
local Types = require(ReplicatedStorage.API.Types)
local GetPrimaryPart = require(ReplicatedStorage.Shared.RoundRule.Common.GetPrimaryPart)

local possessedProps: {[Types.MapObject]: RBXScriptConnection} = {}

local function stopPossess(player: Player): ()
	for prop, destroying in possessedProps do
		if prop:GetAttribute("PossessedBy") == player.UserId then
			prop:SetAttribute("PossessedBy", nil)
			prop:RemoveTag("Possessed")
			possessedProps[prop] = nil

			destroying:Disconnect()

			local primaryPart = GetPrimaryPart(prop)
			if primaryPart and primaryPart:IsDescendantOf(workspace) then
				primaryPart:SetNetworkOwnershipAuto()
			end

			break
		end
	end
end

ReplicatedStorage.Remotes.ClientServer.PossessProp.OnServerEvent:Connect(function(player, prop: unknown): ()
	if prop == nil then
		stopPossess(player)
		return
	end

	if typeof(prop) ~= "Instance" then
		return
	end

	local id = prop:GetAttribute("PossessedBy")
	if typeof(id) == "number" then
		local possessingPlayer = Players:GetPlayerByUserId(id)
		if possessingPlayer then
			local participant = GetParticipant(possessingPlayer)
			if not participant or (participant and participant:IsAlive()) then
				return
			end
		end
	end

	if not prop:IsA("BasePart") and not prop:IsA("Model") then
		return
	end

	if not prop:HasTag("Prop") or prop:HasTag("Interactable") or prop:HasTag("Corpse") then
		return
	end

	local primaryPart = GetPrimaryPart(prop)
	if not primaryPart then
		return
	end

	local participant = GetParticipant(player)
	if participant and participant:IsAlive() then
		return
	end

	stopPossess(player)

	prop:SetAttribute("PossessedBy", player.UserId)
	prop:AddTag("Possessed")

	local destroying = prop.Destroying:Once(function()
		stopPossess(player)
	end)
	possessedProps[prop] = destroying

	primaryPart:SetNetworkOwner(player)
end)

table.insert(RoundHandler.OnCharacterAdded, function(_, participant)
	stopPossess(participant.Player)
end)

return nil