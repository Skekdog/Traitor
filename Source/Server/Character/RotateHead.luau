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

	local neck = char:FindFirstChild("Neck", true)
	if not neck or not neck:IsA("AnimationConstraint") or not neck.Attachment1 then
		return
	end

	y = math.clamp(y, -1.4, 1.4)
	neck.Attachment1.CFrame = CFrame.new(neck.Attachment1.Position) * CFrame.Angles(-y, 0, 0)
end)

return nil