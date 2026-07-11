local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GetRemote = require(ReplicatedStorage.API.GetRemote)

local replicateSwimState = GetRemote("SwimState", ReplicatedStorage.Remotes.ClientServer)

replicateSwimState.OnServerEvent:Connect(function(player): ()
	local char = player.Character
	if not char then
		return
	end

	local humanoid = char:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	-- This is apparently enough to fix drowning with the avatar abilities library. Don't ask how
	humanoid:ChangeState(Enum.HumanoidStateType.Swimming)
end)

return nil