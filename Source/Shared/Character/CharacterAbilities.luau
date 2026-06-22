local LocalCharacter = require(script.Parent.LocalCharacter)

local MAX_FORCE = 500

LocalCharacter.Character:Connect(function(char)
	if not char then
		return
	end

	local controllerManager = char:WaitForChild("ControllerManager")
	if not controllerManager or not controllerManager:IsA("ControllerManager") then
		return
	end

	local airController = controllerManager:WaitForChild("AirController")
	if not airController or not airController:IsA("AirController") then
		return
	end

	airController.MoveMaxForce = MAX_FORCE
end)

return nil
