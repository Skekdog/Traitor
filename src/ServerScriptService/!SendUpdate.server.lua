local ServerScriptService = game:GetService("ServerScriptService")
local ProfileService = require(ServerScriptService:FindFirstChild("PlayerSetup"):FindFirstChild("ProfileService"))

local newVersion = "0.8.4"
ServerScriptService:FindFirstChild("RoundHandler"):SetAttribute("Version", newVersion)

local profile: ProfileService.Profile & {Data: {Version: string}} = ProfileService.GetProfileStore("GameData_v2", {Version = "0.0.0"}):LoadProfileAsync("Version")
profile:Reconcile()
profile.Data.Version = newVersion
profile:Release()

--todo in future update:
-- new maps (siberia and remake nuketown)
-- fix primary fire not respecting settings
-- roundhandler v2
-- ladders