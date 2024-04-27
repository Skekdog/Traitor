local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local roundInfo = nil
local plr = Players.LocalPlayer

local scriptCons = game:WaitForChild("ClientStorage"):WaitForChild("ScriptConnections")

scriptCons:WaitForChild("PingRadarEvent").Event:Connect(function()
	(workspace :: any).RadarPoints:ClearAllChildren()
	
	local info = roundInfo:InvokeServer(plr:GetAttribute("CurrentRound"),"Players")
	if info then
		for i,v in info.Players do
			if v and v.Character and (v.Name ~= plr.Name) and v.Character:FindFirstChild("Humanoid") and (v.Character:FindFirstChild("Humanoid").Health > 0) then
				local clone = ReplicatedFirst.RadarPoint:Clone()
				clone:SetPrimaryPartCFrame(v.Character.HumanoidRootPart.CFrame)
				clone.RadarPoint.TextLabel.Text = math.round(plr:DistanceFromCharacter(v.Character.HumanoidRootPart.Position))
				clone.RadarPoint.Enabled = true
				clone.Parent = (workspace :: any).RadarPoints
			end
		end
	end
end)