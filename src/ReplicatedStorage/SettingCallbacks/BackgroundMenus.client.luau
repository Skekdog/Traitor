local UIManager = require(script.Parent.Parent.UIManager)
local SettingCallbacks = require(script.Parent.SettingCallbacks)
SettingCallbacks.Listen(function(settingName: string, value: any)
    if settingName ~= "Background Menus" then
        return
    end   
    UIManager.BackgroundMenuMode = value
end)
