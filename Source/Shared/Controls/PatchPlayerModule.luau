local StarterPlayer = game:GetService("StarterPlayer")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")
local ControlModule = require(StarterPlayer.PlayerModule.ControlModule)

function ControlModule:UpdateTouchGuiVisibility()
	local doShow = GuiService.TouchControlsEnabled and UserInputService.PreferredInput == Enum.PreferredInput.Touch

	if doShow and not self.touchGui then
		self:CreateTouchGuiContainer()
	end

	if self.touchGui then
		self.touchGui.Enabled = doShow
	end
end

ControlModule:UpdateMovementMode()
ControlModule:UpdateTouchGuiVisibility()

return nil