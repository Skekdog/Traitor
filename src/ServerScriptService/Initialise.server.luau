local BadgeService = game:GetService("BadgeService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local ProfileManager = require(script.Parent.ProfileManager)

local _earlyTesters = {
	2356511943,
	315415902,
	305546034,
	2021782328,
	157359649,
	120380298,
	1939149799,
	879872945,
	706326447,
	629091420,
	519873663,
	19990629,
	4132746558,
	3541273531,
	4051361442,
	3106058458,
}

local function sendSavedSettings(plr: Player, profile: ProfileManager.Profile)
	ReplicatedStorage.ServerClient.LoadSavedSettings:FireClient(plr, profile.Data.Settings)
end

Players.PlayerAdded:Connect(function(plr): ()
	if ServerStorage:GetAttribute("ServerLocked") then
		return plr:Kick("This server is shutting down.")
	end
	
    local profile = ProfileManager.LoadProfile(plr)
	plr:SetAttribute("Score", 0)
	plr:SetAttribute("TotalScore", 0)
	if profile then
        sendSavedSettings(plr, profile)
		plr:SetAttribute("TotalScore", profile.Data.TotalPoints)
    end

	local tries = 0
	local suc = false
	repeat
		suc = pcall(function()
			BadgeService:AwardBadge(plr.UserId, 2136698808)
		end)
		task.wait(1)
	until suc or tries > 3
end)

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