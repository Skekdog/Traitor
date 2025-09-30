local ReplicatedStorage = game:GetService("ReplicatedStorage")
local IsBadNumber = require(ReplicatedStorage.Shared.Util.IsBadNumber)

ReplicatedStorage.Remotes.ClientServer.RotateHead.OnServerEvent:Connect(function(plr, y: unknown)
	local char = plr.Character
	if not char then
		return
	end

	if typeof(y) ~= "number" or IsBadNumber(y) then
		return
	end

	local neck = char:FindFirstChild("Neck", true)
	if not neck or not neck:IsA("Motor6D") then
		return
	end

	y = math.clamp(y, -1.4, 1.4)
	neck.C0 = CFrame.new(neck.C0.Position) * CFrame.Angles(y, 0, 0)
end)

return nil