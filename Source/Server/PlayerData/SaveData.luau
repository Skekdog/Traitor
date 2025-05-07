local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProfileManager = require(script.Parent.ProfileManager)

local maxSettingsLength = ProfileManager.ProfileTemplate.Settings:len() * 1.2
ReplicatedStorage.Remotes.ClientServer.SaveSettings.OnServerEvent:Connect(function(plr, options: unknown)
	if typeof(options) ~= "string" then
		return
	end

	if options:len() > maxSettingsLength then
		return warn(`Settings length exceeds max {maxSettingsLength} characters!`)
	end

    ProfileManager.UpdateProfile(plr, "Settings", options)
end)

return nil