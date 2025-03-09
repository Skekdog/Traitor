local StarterGui = game:GetService("StarterGui")

local ThemesManager = require(script.Parent.ThemesManager)
local UIManager = require(script.Parent.UIManager)

ThemesManager.UpdateTheme("Dark")

local notice = UIManager.WaitForUI("Notice") :: UIManager.UI & {Object: typeof(UIManager.UnregisteredUIs.Notice)}
notice:ToggleVisible(true)

StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)

return nil