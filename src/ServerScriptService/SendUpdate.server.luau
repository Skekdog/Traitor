local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local ProfileService = (require)(ServerScriptService.ProfileService:Clone())

local newVersion = "0.9.1"
ServerStorage:SetAttribute("Version", newVersion)

local profile = ProfileService.GetProfileStore("GameData_v2", {Version = "0.0.0"}):LoadProfileAsync("Version")
profile:Reconcile()
profile.Data.Version = newVersion
profile:Save()
profile:Release()

print("Updated version to " .. newVersion)