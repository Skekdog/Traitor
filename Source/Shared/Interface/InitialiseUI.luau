local StarterGui = game:GetService("StarterGui")

local ThemesManager = require(script.Parent.UILib.ThemesManager)
ThemesManager.UpdateTheme("Dark")

require(script.Parent.Welcome)

StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)

return nil