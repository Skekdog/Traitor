local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local LocalParticipantInfo = require(ReplicatedStorage.Shared.LocalState.LocalParticipantInfo)
local Types = require(ReplicatedStorage.Shared.RoundRule.Types)

export type ActionNodeParams = {
	Adornee: Types.MapThing,
	Title: string,
	Cost: number,
	Cooldown: number,
	Radius: number,
	Action: (user: Types.Participant) -> (),
}

local nodes: {[BillboardGui]: true?} = {}

local nodeGui = Instance.new("BillboardGui")

do
	nodeGui.Size = UDim2.new(1, 200, 1, 50)
	nodeGui.Name = "ActionNodeGui"

	local frame = Instance.new("Frame", nodeGui)
	frame.Size = UDim2.fromScale(1, 1)
end

ReplicatedStorage.Remotes.ClientServer.ActionNode.OnClientEvent:Connect(function(node: ActionNodeParams): ()
	if not node.Adornee then
		return
	end

	local gui = nodeGui:Clone()
	gui.Adornee = node.Adornee
	gui.Parent = Players.LocalPlayer.PlayerGui -- according to the docs, input events will not work unless parented to PlayerGui

	nodes[gui] = true

	node.Adornee.Destroying:Connect(function()
		gui:Destroy()
		nodes[gui] = nil
	end)
end)

local roleValue = LocalParticipantInfo.GetParticipant().Role

RunService.PreRender:Connect(function()
	local timeNow = workspace:GetServerTimeNow()
	local role = roleValue()

	for gui in nodes do
		gui.Enabled = (role.Definition.IsBadGuys or false) and (gui.Adornee:GetAttribute("CooldownUntil") :: number? or 0) > timeNow
	end
end)

return nil