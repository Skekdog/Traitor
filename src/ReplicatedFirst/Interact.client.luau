local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local ReplicatedFirst = game:GetService("ReplicatedFirst")

local LocalRoundInfo = require(ReplicatedFirst.LocalRoundInfo)
local Controls = require(ReplicatedFirst.ControlManager)

local plr = Players.LocalPlayer
local cam = workspace.CurrentCamera

local params = RaycastParams.new()
params.IgnoreWater = true

Controls.Register("Interact", true, function(action, state, input, toggled)
	if state ~= Enum.UserInputState.End then
		return
	end
	local map = LocalRoundInfo.GetMap()

	if not map then
		return
	end

	local char = plr.Character
	if char then
		params.FilterDescendantsInstances = {char}
	end

	local ray = workspace:Raycast(cam.CFrame.Position, cam.CFrame.LookVector * 10, params)
	if not ray or not ray.Instance or not ray.Instance.Parent then
		return
	end

	if ray.Instance.Parent:GetAttribute("IsCorpse") then
		return (ray :: any).Instance.Parent.SearchCorpse:FireServer()
	end

	if not char or not map then
		return
	end

	local actionItems = map.Map:FindFirstChild("__ActionItems")
	local doors = map.Map:FindFirstChild("__Doors")
	local props = map:FindFirstChild("Props")
	if (actionItems and actionItems:IsAncestorOf(ray.Instance)) or (doors and doors:IsAncestorOf(ray.Instance)) or (props and props:IsAncestorOf(ray.Instance)) then
		RS.ClientServer.Interaction:FireServer(ray.Instance)
	end
end)