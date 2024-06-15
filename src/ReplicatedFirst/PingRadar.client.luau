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

		local char = v.Player.Character
		if not char then
			continue
		end

		local root = char:FindFirstChild("HumanoidRootPart") :: BasePart
		local hum = char:FindFirstChildOfClass("Humanoid")

		if not root or not hum or hum.Health <= 0 then
			continue
		end

		local clone = ReplicatedStorage.RadarPoint:Clone()
		clone:PivotTo(root.CFrame)
		clone.RadarPoint.TextLabel.Text = tostring(math.round(plr:DistanceFromCharacter(root.Position)))
		clone.RadarPoint.Enabled = true
		clone.Parent = workspace.RadarPoints :: any
	end
end)