local BadgeService = game:GetService("BadgeService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local ProfileManager = require(ServerScriptService.PlayerData.ProfileManager)
local RoundHandler = require(ServerScriptService.RoundHandler)
local KarmaManager = require(script.Parent.KarmaManager)
local ScoreManager = require(script.Parent.ScoreManager)

local function sendSavedSettings(plr: Player, profile: ProfileManager.Profile)
	ReplicatedStorage.Remotes.ServerClient.LoadSavedSettings:FireClient(plr, profile.Data.Settings)
end

local BADGE_ID = 2136698808

local function tryAwardTesterBadge(plr: Player): ()
	local _, hasBadge = pcall(function()
		return BadgeService:UserHasBadgeAsync(plr.UserId, BADGE_ID)
	end)

	if hasBadge then
		return
	end

	local tries = 0
	local suc = false
	repeat
		suc = pcall(function()
			BadgeService:AwardBadgeAsync(plr.UserId, BADGE_ID)
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

Players.PlayerRemoving:Connect(function(plr)
	local round = RoundHandler.GetRound()
    local participant = round:GetParticipant(plr.Name)

	local totalScore = ScoreManager.GetTotalScore(plr)
	if participant and totalScore then
		for _, v in participant.Scores do
			assert(v)
			totalScore += v
		end
	end

	if totalScore then
		ScoreManager.SetTotalScore(plr, totalScore)
	end

    if participant then
        KarmaManager.SetKarma(plr, participant:GetKarma())
		round:RemoveParticipant(participant, false)
    end

    ProfileManager.ReleaseProfile(plr)
end)

return nil