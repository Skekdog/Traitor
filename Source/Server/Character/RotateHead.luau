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

	y = math.clamp(-y, -1.4, 1.4)

	local neck = char:FindFirstChild("Neck", true)
	if neck and neck:IsA("AnimationConstraint") and neck.Attachment0 then
		neck.Attachment0.CFrame = CFrame.new(neck.Attachment0.Position) * CFrame.Angles(-y, 0, 0)
	end

	local rightShoulder = char:FindFirstChild("RightShoulder", true)
	if rightShoulder and rightShoulder:IsA("AnimationConstraint") and rightShoulder.Attachment0 then
		rightShoulder.Attachment0.CFrame = CFrame.new(rightShoulder.Attachment0.Position) * CFrame.Angles(-y, 0, 0)
	end

	local leftShoulder = char:FindFirstChild("LeftShoulder", true)
	if leftShoulder and leftShoulder:IsA("AnimationConstraint") and leftShoulder.Attachment0 then
		leftShoulder.Attachment0.CFrame = CFrame.new(leftShoulder.Attachment0.Position) * CFrame.Angles(-y, 0, 0)
	end
end)

return nil