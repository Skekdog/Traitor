local StarterPlayer = game:GetService("StarterPlayer")
local CameraInput = require(StarterPlayer.PlayerModule.CameraModule.CameraInput)

local OriginalFunction = CameraInput.getRotation

return function(multiplier: number): ()
	function CameraInput.getRotation(...)
		return OriginalFunction(...) * multiplier
	end
end
