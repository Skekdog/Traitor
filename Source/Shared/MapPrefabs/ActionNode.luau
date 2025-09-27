local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RoundHandler = require(ServerScriptService.RoundHandler)
local ActionNodeType = require(ReplicatedStorage.Shared.Actions.ActionNodeType)
local GetPrimaryPart = require(ReplicatedStorage.Shared.RoundRule.Common.GetPrimaryPart)
local Types = require(ReplicatedStorage.Shared.RoundRule.Types)

local nodes: {[Types.MapObject]: ActionNodeType.ActionNodeParams?} = {}

local function replicateNode(node: ActionNodeType.ActionNodeParams, player: Player?): ()
	if player then
		ReplicatedStorage.Remotes.ClientServer.ActionNode:FireClient(player, node)
	else
		ReplicatedStorage.Remotes.ClientServer.ActionNode:FireAllClients(node)
	end
end

local function useNode(node: ActionNodeType.ActionNodeParams, participant: Types.Participant): ()
	participant:SetCredits(participant:GetCredits() - node.Cost)
	node.Adornee:SetAttribute("CooldownUntil", workspace:GetServerTimeNow() + node.Cooldown)
	node.Action(participant)
end

local function ActionNode(params: ActionNodeType.ActionNodeParams): ()
	nodes[params.Adornee] = params
	replicateNode(params)

	params.Adornee.Destroying:Connect(function()
		nodes[params.Adornee] = nil
	end)
end

ReplicatedStorage.Remotes.ClientServer.ActionNode.OnServerEvent:Connect(function(player, adornee: unknown)
	if typeof(adornee) ~= "Instance" or (not adornee:IsA("BasePart") and not adornee:IsA("Model")) then
		return
	end
	local MapObject = adornee :: Types.MapObject

	local node = nodes[MapObject]
	if not node then
		return
	end

	if node.Adornee:GetAttribute("IsDisabled") then
		return
	end

	if (node.Adornee:GetAttribute("CooldownUntil") :: number? or 0) > workspace:GetServerTimeNow() then
		return
	end

	local distance = player:DistanceFromCharacter(GetPrimaryPart(node.Adornee).Position)
	if distance == 0 or distance > node.Radius * 1.1 then
		return
	end

	local round = RoundHandler.GetRound()
	local participant = round:GetParticipant(player.Name)
	if not participant or not participant:IsEvil() or participant:GetCredits() < node.Cost or not participant:IsAlive() then
		return
	end

	useNode(node, participant)
end)

Players.PlayerAdded:Connect(function(player)
	for i, node in nodes do
		assert(node)
		replicateNode(node, player)
	end
end)

return ActionNode