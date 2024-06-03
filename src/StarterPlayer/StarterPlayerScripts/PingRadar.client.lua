local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalRoundInfo = require(ReplicatedFirst.LocalRoundInfo)
local plr = Players.LocalPlayer

ReplicatedFirst.ClientStorage.ScriptConnections.PingRadarEvent.Event:Connect(function()
	workspace.RadarPoints:ClearAllChildren()
	
	local info = LocalRoundInfo.GetAllParticipants()
	for _, v in info do
		if v.Player == plr then
			continue
		end
		local char: any = v.Player.Character
		if char and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0 then
			local clone = ReplicatedStorage.RadarPoint:Clone()
			clone:PivotTo(char.HumanoidRootPart.CFrame)
			clone.RadarPoint.TextLabel.Text = tostring(math.round(plr:DistanceFromCharacter(char.HumanoidRootPart.Position)))
			clone.RadarPoint.Enabled = true
			clone.Parent = workspace.RadarPoints :: any
		end
	end
end)