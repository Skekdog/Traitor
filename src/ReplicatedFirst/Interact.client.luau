local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local ReplicatedFirst = game:GetService("ReplicatedFirst")

local LocalRoundInfo = require(ReplicatedFirst.LocalRoundInfo)
local Controls = require(ReplicatedFirst.ControlManager)

local plr = Players.LocalPlayer
local cam = workspace.CurrentCamera

local params = RaycastParams.new()
params.IgnoreWater = true

local clientStorage = ReplicatedFirst.ClientStorage
clientStorage:GetAttributeChangedSignal("IsSpectating"):Connect(function()
	if clientStorage:GetAttribute("IsSpectating") then
		Controls.Unregister("Interact")
	else
		Controls.Register("Interact", true, function(action, state, input, toggled)
			local map = LocalRoundInfo.GetMap()
	
			local char = plr.Character
			if not char or not map then return end
	
			params.FilterDescendantsInstances = {char}
			local ray = workspace:Raycast(cam.CFrame.Position, cam.CFrame.LookVector * 10, params)

			if not ray or not ray.Instance then return end
			if map.ActionItems:IsAncestorOf(ray.Instance) or map.Doors:IsAncestorOf(ray.Instance) or map.Props:IsAncestorOf(ray.Instance) then
				RS.ClientServer.Interaction:FireServer(ray.Instance)
			end
		end)
	end
end)