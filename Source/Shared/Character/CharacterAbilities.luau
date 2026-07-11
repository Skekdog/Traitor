local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Abilities = require(ReplicatedStorage.Shared.RoundRule.Common.Abilities)
local LocalCharacter = require(script.Parent.LocalCharacter)

local MAX_FORCE = 500 -- Prevent most movement whilst airborne
local DECELERATION_TIME = 0.4 -- Fix instantly stopping when landing on the ground. IMO that's a Roblox bug but for now I can fix it like this

local DISABLED_ABILITIES = {
	"FallingDown",
	"Climbing",
	"Sitting",
}

LocalCharacter.Character:Connect(function(char)
	if not char then
		return
	end

	for _, abilityName in DISABLED_ABILITIES do
		Abilities.GetAbilityState(char, abilityName):SetAttribute("Enabled", false)
	end
end)

LocalCharacter.Controllers:Connect(function(controllers)
	if not controllers then
		return
	end

	controllers.Ground.DecelerationTime = DECELERATION_TIME
	controllers.Air.MoveMaxForce = MAX_FORCE
end)

return nil
