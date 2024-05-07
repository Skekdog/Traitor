local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local SettingsManager = require(ReplicatedFirst.SettingsManager)
local ProfileService = require(script:FindFirstChild("ProfileService"))

local profileTemplate = {
	Karma = 1000,
	Settings = SettingsManager.JSONEncode(),
	TotalPoints = 0,
	AvailablePoints = 0,
	PurchasedAccessories = {},
	BannedUntil = 0,
	BanReason = "",
}

type PlayerData = typeof(profileTemplate)
type Profile = ProfileService.Profile & {Data: PlayerData}

local profiles: {[Player]: Profile} = {}
local ProfileStore = ProfileService.GetProfileStore("PlayerData_v2", profileTemplate)

local ClientServer = ReplicatedStorage.ClientServer

Players.PlayerAdded:Connect(function(plr)
	if ServerStorage:GetAttribute("ServerLocked") then
		return plr:Kick("This server is shutting down.")
	end
	Instance.new("Folder", plr).Name = "Inventory"
	
	local profile: Profile = ProfileStore:LoadProfileAsync("Player"..plr.UserId)
	if profile then
		profile:AddUserId(plr.UserId)
		profile:Reconcile()
		profile:ListenToRelease(function()
			profiles[plr] = nil
		end)
		
		if plr:IsDescendantOf(Players) then
			profiles[plr] = profile
			ReplicatedStorage.ServerClient.LoadSavedData:FireClient(plr, profile.Data.Settings)
		else
			-- Player left before the profile loaded
			profile:Release()
		end
	else
		plr:Kick("You have been kicked to maintain data integrity. Try again later.")
	end
	return
end)

Players.PlayerRemoving:Connect(function(plr)
	local profile = profiles[plr]
	if profile then
		profile:Release()
	end
end)

ClientServer.SaveSettings.OnServerEvent:Connect(function(plr, options: string)
	if typeof(options) ~= "string" then
		return
	end
	if options:len() > profileTemplate.Settings:len()*1.2 then
		return warn("Settings length exceeds maximum "..tostring(profileTemplate.Settings:len()*1.2).." characters!")
	end
	profiles[plr].Data.Settings = options
	return
end)

local get = script:FindFirstChild("GetProfile")
get.OnInvoke = function(plr: Player)
	if not profiles[plr] then
		return warn(plr.Name.." profile not found!")
	end
	return profiles[plr].Data
end

local update = script:FindFirstChild("UpdateProfile")
update.Event:Connect(function(plr: Player, key: string, value: string | number)
	if not profiles[plr] then
		return warn(plr.Name.." profile not found!")
	end
	profiles[plr].Data[key] = value
	return
end)

-- Only called once - when restarting
local releaseAllProfiles = script:FindFirstChild("ReleaseAllProfiles")
releaseAllProfiles.Event:Once(function()
	for _, v in profiles do
		v:Release()
	end
end)