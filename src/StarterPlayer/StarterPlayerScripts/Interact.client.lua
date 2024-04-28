local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local ReplicatedFirst = game:GetService("ReplicatedFirst")

local plr = Players.LocalPlayer
local cam = workspace.CurrentCamera

local params = RaycastParams.new()
params.IgnoreWater = true

local RoundHandlerTypes = require(ReplicatedFirst.RoundHandlerTypes)
local Controls = require(game:GetService("ReplicatedFirst").ControlManager)

plr:GetAttributeChangedSignal("CurrentRoundID"):Connect(function()
	Controls.Register("Interact", true, function(action, state, input, toggled)
		local map: RoundHandlerTypes.MapStructure? = (game :: any).ClientStorage.CurrentMapObject.Value

		local char = plr.Character
		if not char or not map then return end

		params.FilterDescendantsInstances = {char}
		local ray = workspace:Raycast(cam.CFrame.Position,cam.CFrame.LookVector * 10,params)
		if ray then
			local inst = ray.Instance
			if inst then
				if (map :: any):FindFirstChild("ActionItems"):IsAncestorOf(inst) or (map :: any):FindFirstChild("Doors"):IsAncestorOf(inst) or map.Props:IsAncestorOf(inst) then
					RS.ClientServer.Interaction:FireServer(inst)
				end
			end
		end
	end)
end)

plr:GetAttributeChangedSignal("IsSpectator"):Connect(function()
	if plr:GetAttribute("IsSpectator") then
		Controls.Unregister("Interact")
	end
end)