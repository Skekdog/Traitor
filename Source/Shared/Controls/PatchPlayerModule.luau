local StarterPlayer = game:GetService("StarterPlayer")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")
local CharacterUtil = require(StarterPlayer.PlayerModule.CommonUtils.CharacterUtil)
local ControlModule = require(StarterPlayer.PlayerModule.ControlModule)
local TouchJump = require(StarterPlayer.PlayerModule.ControlModule.TouchJump)

function ControlModule:UpdateTouchGuiVisibility()
	local doShow = GuiService.TouchControlsEnabled and UserInputService.PreferredInput == Enum.PreferredInput.Touch

	if doShow and not self.touchGui then
		self:CreateTouchGuiContainer()
	end

	if self.touchGui then
		self.touchGui.Enabled = doShow
	end
end

function TouchJump:UpdateEnabled()
	local humanoid = CharacterUtil.getChild("Humanoid", "Humanoid") :: Humanoid
	if humanoid and self.externallyEnabled and humanoid.JumpPower > 0 and (humanoid:GetStateEnabled(Enum.HumanoidStateType.Jumping) or humanoid:GetState() == Enum.HumanoidStateType.Swimming) then
		self:EnableButton(true)
	else
		self:EnableButton(false)
	end
end

ControlModule:UpdateMovementMode()
ControlModule:UpdateTouchGuiVisibility()

return nil