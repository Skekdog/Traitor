local UserInputService = game:GetService("UserInputService")
local UIManager = require(script.Parent.Parent.UIManager)
local SettingCallbacks = require(script.Parent.SettingCallbacks)

SettingCallbacks.Listen(function(settingName: string, value: any)
    if settingName ~= "Always Show Sidebar" or not UserInputService.KeyboardEnabled then
        return
    end

    local sidebar = UIManager.WaitForUI("Sidebar")
    if sidebar then
        sidebar:ToggleVisible(value)
    end
end)
