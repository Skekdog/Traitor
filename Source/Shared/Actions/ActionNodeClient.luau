local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ActionNodeType = require(script.Parent.ActionNodeType)
local LocalParticipantInfo = require(ReplicatedStorage.Shared.LocalState.LocalParticipantInfo)

local nodes: {[BillboardGui]: true?} = {}

local function makeGui(params: ActionNodeType.ActionNodeParams): ()
	local nodeGui = Instance.new("BillboardGui")
	nodeGui.Size = UDim2.new(1, 200, 1, 50)
	nodeGui.Name = "ActionNodeGui"
	nodeGui.AlwaysOnTop = true
	nodeGui.Active = true

	local frame = Instance.new("Frame", nodeGui)
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundTransparency = 1

	do
		local list = Instance.new("UIListLayout")
		list.SortOrder = Enum.SortOrder.LayoutOrder
		list.FillDirection = Enum.FillDirection.Horizontal
		list.VerticalAlignment = Enum.VerticalAlignment.Center
		list.HorizontalAlignment = Enum.HorizontalAlignment.Left
		list.Parent = frame
	end

	local clickIcon = Instance.new("ImageButton", frame)
	clickIcon.Image = "rbxasset://textures/cursors/KeyboardMouse/ArrowCursor.png"
	clickIcon.Size = UDim2.fromScale(1, 1)
	clickIcon.ImageColor3 = Color3.new(1, 0.5, 0.5)
	clickIcon.BackgroundTransparency = 1
	clickIcon.ImageTransparency = 0.5

	do
		local aspectRatio = Instance.new("UIAspectRatioConstraint")
		aspectRatio.Parent = clickIcon
	end

	local infoFrame = Instance.new("Frame")
	infoFrame.Size = UDim2.fromScale(100, 1)
	infoFrame.BackgroundTransparency = 1
	infoFrame.Visible = false

	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Text = params.Title
	title.TextScaled = true
	title.Size = UDim2.fromScale(1, 0.5)
	title.TextColor3 = Color3.new(1, 0, 0)
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.AutomaticSize = Enum.AutomaticSize.X
	title.Font = Enum.Font.SourceSans
	title.TextStrokeTransparency = 0
	title.BackgroundTransparency = 1
	title.Parent = infoFrame

	if params.Cost ~= 0 then
		local cost = title:Clone()
		cost.Position = UDim2.fromScale(0, 0.5)
		cost.Text = `(Costs {params.Cost} {if params.Cost == 1 then "credit" else "credits"})`
		cost.Parent = infoFrame
	end

	infoFrame.Parent = frame

	clickIcon.MouseEnter:Connect(function()
		clickIcon.ImageTransparency = 0
		infoFrame.Visible = true
	end)

	clickIcon.MouseLeave:Connect(function()
		clickIcon.ImageTransparency = 0.5
		infoFrame.Visible = false
	end)

	clickIcon.Activated:Connect(function()
		ReplicatedStorage.Remotes.ClientServer.ActionNode:FireServer(params.Adornee)
	end)

	params.Adornee.Destroying:Connect(function()
		nodeGui:Destroy()
		nodes[nodeGui] = nil
	end)

	nodes[nodeGui] = true

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

	for gui in nodes do
		gui.Enabled = (role.Definition.IsBadGuys or false) and (gui.Adornee:GetAttribute("CooldownUntil") :: number? or 0) < timeNow
	end
end)

return nil