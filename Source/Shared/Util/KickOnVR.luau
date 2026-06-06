local Players = game:GetService("Players")
local VRService = game:GetService("VRService")
local InstanceSignal = require(script.Parent.InstanceSignal)

InstanceSignal.ListenProperty<<boolean>>(VRService, "VREnabled"):Connect(function(enabled)
	if enabled then
		Players.LocalPlayer:Kick("VR is not supported.")
	end
end, true)

return nil