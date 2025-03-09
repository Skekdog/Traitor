local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProfileManager = require(script.Parent.ProfileManager)

local maxSettingsLength = ProfileManager.ProfileTemplate.Settings:len() * 1.2
ReplicatedStorage.ClientServer.SaveSettings.OnServerEvent:Connect(function(plr, options: unknown)
	if typeof(options) ~= "string" then
		return
	end

	if options:len() > maxSettingsLength then
		return warn(`Settings length exceeds max {maxSettingsLength} characters!`)
	end

    ProfileManager.UpdateProfile(plr, "Settings", options)
end)

Players.PlayerRemoving:Connect(function(plr)
	ProfileManager.ReleaseProfile(plr)
end)

return nil