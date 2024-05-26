local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedFirst.RoundHandler.Types)
local plr = Players.LocalPlayer

ReplicatedFirst.ClientStorage.ScriptConnections.PingRadarEvent.Event:Connect(function()
	workspace.RadarPoints:ClearAllChildren()
	
	local info: {Types.PartialParticipant}? = ReplicatedStorage.RoundHandler.GetPartialParticipants:InvokeServer()
	if info then
		for _, v in info do
			local char: any = v.Player.Character
			if char and (char.Name ~= plr.Name) and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0 then
				local clone = ReplicatedStorage.RadarPoint:Clone()
				clone:PivotTo(char.HumanoidRootPart.CFrame)
				clone.RadarPoint.TextLabel.Text = tostring(math.round(plr:DistanceFromCharacter(char.HumanoidRootPart.Position)))
				clone.RadarPoint.Enabled = true
				clone.Parent = workspace.RadarPoints :: any
			end
		end
	end
end)