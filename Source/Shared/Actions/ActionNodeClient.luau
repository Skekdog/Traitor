local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ActionNodeType = require(script.Parent.ActionNodeType)
local LocalParticipantInfo = require(ReplicatedStorage.Shared.LocalState.LocalParticipantInfo)

export type ClientNodeData = {
	Info: TextLabel,
	ClickIcon: ImageButton,
	Params: ActionNodeType.ActionNodeParams,
}

local module = {}

local activeNode: ClientNodeData?
function module.GetActiveNode(): ClientNodeData?
	return activeNode
end

local nodes: {[BillboardGui]: ActionNodeType.ActionNodeParams?} = {}

local function deselect(nodeData: ClientNodeData): ()
	if activeNode == nodeData then
		activeNode = nil
	end
	nodeData.ClickIcon.ImageTransparency = 0.5
	nodeData.Info.Visible = false
	nodeData.ClickIcon:RemoveTag("ControlHint")
end

function module.Activate(node: ClientNodeData): ()
	deselect(node)
	ReplicatedStorage.Remotes.ClientServer.ActionNode:FireServer(node.Params.Adornee)
end

local function setHintAttributes(instance: Instance): ()
	instance:SetAttribute("Control", "Interact")
	instance:SetAttribute("NoStyle", true)
	instance:SetAttribute("AnchorPoint", Vector2.new(0, 0.25))
	instance:SetAttribute("Position", UDim2.fromScale(0.75, 0.5))
	instance:SetAttribute("TextXAlignment", "Left")
	instance:SetAttribute("AlwaysShow", true)
end

local function makeGui(params: ActionNodeType.ActionNodeParams): ()
	local nodeGui = Instance.new("BillboardGui")
	nodeGui.Size = UDim2.new(1, 200, 1, 50)
	nodeGui.Name = "ActionNodeGui"
	nodeGui.AlwaysOnTop = true
	nodeGui.Active = true
	nodeGui.ResetOnSpawn = false
	nodeGui.MaxDistance = params.Radius

	local frame = Instance.new("Frame", nodeGui)
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundTransparency = 1

	local clickIcon = Instance.new("ImageButton", frame)
	clickIcon.Image = "rbxassetid://91264198270381"
	clickIcon.Size = UDim2.fromScale(1, 1)
	clickIcon.ImageColor3 = Color3.new(1, 0.5, 0.5)
	clickIcon.AnchorPoint = Vector2.new(0.5, 0.5)
	clickIcon.Position = UDim2.fromScale(0.5, 0)
	clickIcon.ScaleType = Enum.ScaleType.Fit
	clickIcon.BackgroundTransparency = 1
	clickIcon.ImageTransparency = 0.5

	Instance.new("UIAspectRatioConstraint", clickIcon)

	setHintAttributes(clickIcon)

	local info = Instance.new("TextLabel")
	info.BackgroundTransparency = 1
	info.Text = params.Title .. (if params.Cost ~= 0 then `\nCosts {params.Cost} {if params.Cost == 1 then "credit" else "credits"}` else "")
	info.TextScaled = true
	info.Size = UDim2.fromScale(1, 1)
	info.Position = UDim2.fromScale(0, 0.5)
	info.TextColor3 = Color3.new(1, 0.5, 0.5)
	info.TextXAlignment = Enum.TextXAlignment.Center
	info.Font = Enum.Font.BuilderSans
	info.BackgroundTransparency = 1
	info.Visible = false
	info.Parent = frame

	local nodeData: ClientNodeData = {
		Info = info,
		ClickIcon = clickIcon,
		Params = params,
	}

	do
		local uiStroke = Instance.new("UIStroke", info)
		uiStroke.Thickness = 2
	end

	clickIcon.MouseEnter:Connect(function()
		activeNode = nodeData
		clickIcon.ImageTransparency = 0
		info.Visible = true
		clickIcon:AddTag("ControlHint")
	end)

	clickIcon.MouseLeave:Connect(function()
		deselect(nodeData)
	end)

	clickIcon.TouchTap:Connect(function()
		module.Activate(nodeData)
	end)

	params.Adornee.Destroying:Connect(function()
		nodeGui:Destroy()
		nodes[nodeGui] = nil

		if activeNode == nodeData then
			activeNode = nil
		end
	end)

	nodes[nodeGui] = params

	nodeGui.Adornee = params.Adornee
	nodeGui.Parent = Players.LocalPlayer.PlayerGui -- according to the docs, input events will not work unless parented to PlayerGui
end

ReplicatedStorage.Remotes.ClientServer.ActionNode.OnClientEvent:Connect(function(node: ActionNodeType.ActionNodeParams): ()
	if not node.Adornee then
		return
	end

	makeGui(node)
end)

local roleValue = LocalParticipantInfo.GetParticipant().Role

RunService.PreRender:Connect(function()
	local timeNow = workspace:GetServerTimeNow()
	local role = roleValue()

	for gui, params in nodes do
		assert(params)
		gui.Enabled = (role.Definition.CanUseActionNodes or false) and (gui.Adornee:GetAttribute("CooldownUntil") :: number? or 0) < timeNow and not gui.Adornee:GetAttribute("IsDisabled")

		if not gui.Enabled and activeNode and activeNode.Params == params then
			activeNode = nil
		end
	end
end)

return table.freeze(module)