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

	local controllerManager = char:WaitForChild("ControllerManager")
	if not controllerManager:IsA("ControllerManager") then
		error("Invalid ControllerManager")
	end

	local airController = controllerManager:WaitForChild("AirController")
	if not airController:IsA("AirController") then
		error("Invalid AirController")
	end

	local groundController = controllerManager:WaitForChild("GroundController")
	if not groundController:IsA("GroundController") then
		error("Invalid GroundController")
	end

	groundController.DecelerationTime = DECELERATION_TIME
	airController.MoveMaxForce = MAX_FORCE

	for _, abilityName in DISABLED_ABILITIES do
		Abilities.GetAbility(char, abilityName):SetAttribute("Enabled", false)
	end
end)

return nil
