local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ProfileManager = require(script.Parent.ProfileManager)

require(script.Parent.SetupPlayer)

Players.PlayerRemoving:Connect(function(plr)
	ProfileManager.ReleaseProfile(plr)
end)

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

ReplicatedStorage.ClientServer.RotateHead.OnServerEvent:Connect(function(plr, y: unknown)
	local char = plr.Character
	if not char then
		return
	end

	if typeof(y) ~= "number" then
		return
	end

	local neck = char:FindFirstChild("Neck", true) :: Motor6D
	if not neck then
		return
	end

	y = math.clamp(y, -1.4, 1.4)
	neck.C0 = CFrame.new(neck.C0.Position) * CFrame.Angles(y, 0, 0)
end)

ReplicatedStorage.ClientServer.GetKarma.OnServerInvoke = function(plr, target: unknown)
	if typeof(target) ~= "Instance" or not target:IsA("Player") then
		return
	end
	local profile = ProfileManager.GetProfile(plr)
	return if profile then profile.Karma else 1000
end

require(script.Parent.RoundHandler)