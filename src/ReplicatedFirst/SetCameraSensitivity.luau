local Players = game:GetService("Players")

local CameraInput = (require)(Players.LocalPlayer.PlayerScripts:WaitForChild("PlayerModule"):WaitForChild("CameraModule"):WaitForChild("CameraInput"))
local OriginalFunction = CameraInput.getRotation

return function(multiplier: number): ()
	function CameraInput.getRotation(...)
		return OriginalFunction(...) * multiplier
	end
end
