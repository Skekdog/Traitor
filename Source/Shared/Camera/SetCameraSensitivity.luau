local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CameraInput = require(ReplicatedStorage.Shared.PlayerModule.CameraModule.CameraInput)

local OriginalFunction = CameraInput.getRotation

return function(multiplier: number): ()
	function CameraInput.getRotation(...)
		return OriginalFunction(...) * multiplier
	end
end
