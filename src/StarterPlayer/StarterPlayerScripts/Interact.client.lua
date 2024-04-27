local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")

local plr = Players.LocalPlayer
local cam = workspace.CurrentCamera

local params = RaycastParams.new()
params.IgnoreWater = true

local Controls = require(game:GetService("ReplicatedFirst").ControlManager)

plr:GetAttributeChangedSignal("CurrentRoundID"):Connect(function()
	Controls.Register("Interact", true, function(action, state, input, toggled)
		local char = plr.Character
		if char then

			params.FilterDescendantsInstances = {char}
			local ray = workspace:Raycast(cam.CFrame.Position,cam.CFrame.LookVector * 10,params)
			if ray then
				local inst:Instance = ray.Instance
				if inst then
					if inst:FindFirstAncestor("ActionItems") or inst:FindFirstAncestor("Doors") or inst:FindFirstAncestor("Props") then
						RS.ClientServer.Interaction:FireServer(inst)
					end
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