local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Settings = require(ReplicatedStorage.Shared.Settings.Settings)
local ProfileService = require(script.Parent.ProfileService)

local module = {}

Settings.PopulateDefaults()

module.ProfileTemplate = {
	Karma = 1000,
	Settings = Settings.JSONEncode(),
	TotalPoints = 0,
	SpentPoints = 0,
	PurchasedAccessories = {},
}

export type PlayerData = typeof(module.ProfileTemplate)
export type Profile = ProfileService.Profile & {Data: PlayerData}

local profiles: {[Player]: Profile} = {}
local ProfileStore = ProfileService.GetProfileStore("PlayerData_v2", module.ProfileTemplate)

function module.LoadProfile(plr: Player): Profile?
    local profile: Profile = ProfileStore:LoadProfileAsync("Player" .. tostring(plr.UserId))
	if profile then
		profile:AddUserId(plr.UserId)
		profile:Reconcile()
		profile:ListenToRelease(function()
			profiles[plr] = nil
		end)
		
		if plr:IsDescendantOf(Players) then
			profiles[plr] = profile
			return profile
		else
			-- Player left before the profile loaded
			profile:Release()
		end
	else
		plr:Kick("You have been kicked to maintain data integrity. Try again later.")
	end
	return
end

function module.ReleaseProfile(plr: Player): ()
    local profile = profiles[plr]
	if profile then
		profile:Release()
	end
end

function module.GetProfile(plr: Player): PlayerData?
	if not profiles[plr] then
		return nil
	end
	return profiles[plr].Data
end

type UpdateProfile =
	((Player, "Karma", number) -> ()) &
	((Player, "Settings", string) -> ()) &
	((Player, "TotalPoints", number) -> ())

module.UpdateProfile = function(plr: Player, key, value): ()
	if not profiles[plr] then
		return
	end
	profiles[plr].Data[key] = value
end :: UpdateProfile

function module.ReleaseAllProfiles(): ()
    for _, v in profiles do
		v:Save()
		v:Release()
	end
end

return module