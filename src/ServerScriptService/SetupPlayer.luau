local BadgeService = game:GetService("BadgeService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local ProfileManager = require(script.Parent.ProfileManager)

local function sendSavedSettings(plr: Player, profile: ProfileManager.Profile)
	ReplicatedStorage.ServerClient.LoadSavedSettings:FireClient(plr, profile.Data.Settings)
end

local function tryAwardTesterBadge(plr: Player): ()
	local tries = 0
	local suc = false
	repeat
		suc = pcall(function()
			BadgeService:AwardBadge(plr.UserId, 2136698808)
		end)
		task.wait(1)
	until suc or tries > 3
end

local function loadAttributes(plr: Player): ()
	plr:SetAttribute("Score", 0)
	plr:SetAttribute("TotalScore", 0)
	plr:SetAttribute("Karma", 1000)
end

local function loadProfile(plr: Player): ()
	local profile = ProfileManager.LoadProfile(plr)
	if profile then
        sendSavedSettings(plr, profile)
		plr:SetAttribute("TotalScore", profile.Data.TotalPoints)
		plr:SetAttribute("Karma", profile.Data.Karma)
    end
end

local function setupPlayer(plr: Player): ()
	if ServerStorage:GetAttribute("ServerLocked") then
		return plr:Kick("This server is shutting down.")
	end
	
    loadAttributes(plr)
	loadProfile(plr)

	tryAwardTesterBadge(plr)
end

Players.PlayerAdded:Connect(setupPlayer)

return nil