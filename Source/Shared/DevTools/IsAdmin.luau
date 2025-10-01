local ReplicatedStorage = game:GetService("ReplicatedStorage")
local IsLabs = require(ReplicatedStorage.Shared.Places.IsLabs)
local meId = 965735486

local function isAdmin(user: number | Player): ()
	local id = if typeof(user) == "Instance" then user.UserId else user
	return id == meId or id < 0 or (IsLabs and workspace:GetAttribute("ServerHost") == id)
end

return isAdmin