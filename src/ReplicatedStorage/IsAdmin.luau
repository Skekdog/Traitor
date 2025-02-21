local RunService = game:GetService("RunService")
local meId = 965735486

local function isAdmin(user: number | Player): ()
	if RunService:IsServer() then
		return true
	end
	
	local id = if typeof(user) == "Instance" then user.UserId else user
	return id == meId or id < 0
end

return isAdmin