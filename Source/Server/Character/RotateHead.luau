local ReplicatedStorage = game:GetService("ReplicatedStorage")
local IsBadNumber = require(ReplicatedStorage.Shared.Util.IsBadNumber)

ReplicatedStorage.Remotes.ClientServer.RotateHead.OnServerEvent:Connect(function(plr, y: unknown)
	local char = plr.Character
	if not char or char:GetAttribute("IsRagdolled") then
		return
	end

	if typeof(y) ~= "number" or IsBadNumber(y) then
		return
	end

	local neckBallSocket = char:FindFirstChild("NeckBallSocket", true)
	if not neckBallSocket or not neckBallSocket:IsA("BallSocketConstraint") then
		return
	end

	local neck = char:FindFirstChild("Neck", true)
	if not neck or not neck:IsA("AnimationConstraint") then
		return
	end
	neck.IsKinematic = false

	y = math.deg(math.clamp(y, -1.4, 1.4))
	neckBallSocket.TwistLowerAngle = y
	neckBallSocket.TwistUpperAngle = y
end)

return nil