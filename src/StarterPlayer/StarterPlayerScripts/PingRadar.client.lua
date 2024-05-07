local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RoundHandlerTypes = require(ReplicatedFirst.RoundHandler.RoundHandlerTypes)
local plr = Players.LocalPlayer

local scriptCons = (game :: any).ClientStorage.ScriptConnections

scriptCons:WaitForChild("PingRadarEvent").Event:Connect(function()
	(workspace :: any).RadarPoints:ClearAllChildren()
	
	local info: {RoundHandlerTypes.PartialParticipant}? = ReplicatedStorage.RoundHandler.GetPartialParticipants:InvokeServer()
	if info then
		for _, v in info do
			local char = v.Player.Character :: any
			if char and (char.Name ~= plr.Name) and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0 then
				local clone = ReplicatedStorage.RadarPoint:Clone()
				clone:PivotTo((char :: any).HumanoidRootPart.CFrame)
				clone.RadarPoint.TextLabel.Text = tostring(math.round(plr:DistanceFromCharacter(char.HumanoidRootPart.Position)))
				clone.RadarPoint.Enabled = true
				clone.Parent = (workspace :: any).RadarPoints
			end
		end
	end
end)