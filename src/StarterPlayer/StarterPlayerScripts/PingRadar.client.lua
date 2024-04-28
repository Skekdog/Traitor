local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RoundHandlerTypes = require(ReplicatedFirst.RoundHandlerTypes)
local plr = Players.LocalPlayer

local scriptCons = game:WaitForChild("ClientStorage"):WaitForChild("ScriptConnections")

scriptCons:WaitForChild("PingRadarEvent").Event:Connect(function()
	(workspace :: any).RadarPoints:ClearAllChildren()
	
	local info: {RoundHandlerTypes.PartialParticipant}? = ReplicatedStorage.RoundHandler.GetPartialParticipants:InvokeServer()
	if info then
		for _, v in info do
			local char = v.Player.Character
			if char and (char.Name ~= plr.Name) and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0 then
				local clone = ReplicatedFirst.RadarPoint:Clone()
				clone:SetPrimaryPartCFrame(v.Character.HumanoidRootPart.CFrame)
				clone.RadarPoint.TextLabel.Text = math.round(plr:DistanceFromCharacter(v.Character.HumanoidRootPart.Position))
				clone.RadarPoint.Enabled = true
				clone.Parent = (workspace :: any).RadarPoints
			end
		end
	end
end)