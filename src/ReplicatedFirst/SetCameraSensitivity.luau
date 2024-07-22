local Players = game:GetService("Players")

local CameraInput = (require :: any)(Players.LocalPlayer.PlayerScripts:WaitForChild("PlayerModule").CameraModule.CameraInput)
local OriginalFunction = CameraInput.getRotation

return function(multiplier: number): ()
	function CameraInput.getRotation(...)
		return OriginalFunction(...) * multiplier
	end
end
