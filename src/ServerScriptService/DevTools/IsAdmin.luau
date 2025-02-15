local meId = 965735486

local function isAdmin(user: number | Player): ()
	local id = if typeof(user) == "Instance" then user.UserId else user
	return id == meId or id < 0
end

return isAdmin