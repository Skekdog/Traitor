local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local VRService = game:GetService("VRService")

warn(VRService.VREnabled, UserInputService.VREnabled)
if VRService.VREnabled or UserInputService.VREnabled then
	Players.LocalPlayer:Kick("VR is not supported!")
end

return nil