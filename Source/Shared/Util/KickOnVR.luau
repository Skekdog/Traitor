local Players = game:GetService("Players")
local VRService = game:GetService("VRService")

if VRService.VREnabled then
	Players.LocalPlayer:Kick("VR is not supported!")
end

return nil