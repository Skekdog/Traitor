local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local USE_DUMMY_AS_CHARACTER = RunService:IsStudio()

local dummy = ServerStorage.Assets.TestDummy

if USE_DUMMY_AS_CHARACTER then
	dummy.Name = "StarterCharacter"
	dummy.Parent = StarterPlayer :: any
end

return dummy