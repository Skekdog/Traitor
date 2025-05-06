local UserInputService = game:GetService("UserInputService")
local function ToggleMouseVisible(visible: boolean): ()
	UserInputService.MouseIconEnabled = visible
end

return ToggleMouseVisible