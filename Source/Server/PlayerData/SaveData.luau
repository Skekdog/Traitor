local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProfileManager = require(script.Parent.ProfileManager)

local MAX_SETTINGS_LENGTH = 10000
ReplicatedStorage.Remotes.ClientServer.SaveSettings.OnServerEvent:Connect(function(plr, options: unknown)
	if typeof(options) ~= "string" then
		return
	end

	if options:len() > MAX_SETTINGS_LENGTH then
		return warn(`Settings length exceeds max {MAX_SETTINGS_LENGTH} characters!`)
	end

    ProfileManager.UpdateProfile(plr, "Settings", options)
end)

return nil