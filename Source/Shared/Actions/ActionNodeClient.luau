local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ActionNodeType = require(script.Parent.ActionNodeType)
local LocalParticipantInfo = require(ReplicatedStorage.Shared.LocalState.LocalParticipantInfo)
local GetPrimaryPart = require(ReplicatedStorage.Shared.RoundRule.Common.GetPrimaryPart)
local Types = require(ReplicatedStorage.Shared.RoundRule.Types)

local nodes: {[BillboardGui]: ActionNodeType.ActionNodeParams?} = {}

local function makeGui(params: ActionNodeType.ActionNodeParams): ()
	local nodeGui = Instance.new("BillboardGui")
	nodeGui.Size = UDim2.new(1, 200, 1, 50)
	nodeGui.Name = "ActionNodeGui"
	nodeGui.AlwaysOnTop = true
	nodeGui.Active = true

	local frame = Instance.new("Frame", nodeGui)
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundTransparency = 1

	local clickIcon = Instance.new("ImageButton", frame)
	clickIcon.Image = "rbxasset://textures/cursors/KeyboardMouse/ArrowCursor.png"
	clickIcon.Size = UDim2.fromScale(1, 1)
	clickIcon.ImageColor3 = Color3.new(1, 0.5, 0.5)
	clickIcon.AnchorPoint = Vector2.new(0.5, 0.5)
	clickIcon.Position = UDim2.fromScale(0.5, 0)
	clickIcon.ScaleType = Enum.ScaleType.Fit
	clickIcon.BackgroundTransparency = 1
	clickIcon.ImageTransparency = 0.5

	local info = Instance.new("TextLabel")
	info.BackgroundTransparency = 1
	info.Text = params.Title .. (if params.Cost ~= 0 then `\nCosts {params.Cost} {if params.Cost == 1 then "credit" else "credits"}` else "")
	info.TextScaled = true
	info.Size = UDim2.fromScale(1, 1)
	info.Position = UDim2.fromScale(0, 0.5)
	info.TextColor3 = Color3.new(1, 0.5, 0.5)
	info.TextXAlignment = Enum.TextXAlignment.Center
	info.Font = Enum.Font.SourceSans
	info.BackgroundTransparency = 1
	info.Visible = false
	info.Parent = frame

	do
		local uiStroke = Instance.new("UIStroke", info)
		uiStroke.Thickness = 2
	end

	clickIcon.MouseEnter:Connect(function()
		clickIcon.ImageTransparency = 0
		info.Visible = true
	end)

	clickIcon.MouseLeave:Connect(function()
		clickIcon.ImageTransparency = 0.5
		info.Visible = false
	end)

	clickIcon.Activated:Connect(function()
		ReplicatedStorage.Remotes.ClientServer.ActionNode:FireServer(params.Adornee)
	end)

	params.Adornee.Destroying:Connect(function()
		nodeGui:Destroy()
		nodes[nodeGui] = nil
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
		local distance = Players.LocalPlayer:DistanceFromCharacter(GetPrimaryPart(gui.Adornee :: Types.MapThing).Position)
		gui.Enabled = (role.Definition.IsBadGuys or false) and (gui.Adornee:GetAttribute("CooldownUntil") :: number? or 0) < timeNow and (distance ~= 0 and distance <= params.Radius)
	end
end)

return nil