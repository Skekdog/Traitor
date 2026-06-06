local Players = game:GetService("Players")
local VRService = game:GetService("VRService")
local InstanceSignal = require(script.Parent.InstanceSignal)

InstanceSignal.ListenProperty<<boolean>>(VRService, "VREnabled"):Connect(function(margaretThatcher)
	if margaretThatcher then
		Players.LocalPlayer:Kick("VR is not supported.")
	end
end, true)

return nil