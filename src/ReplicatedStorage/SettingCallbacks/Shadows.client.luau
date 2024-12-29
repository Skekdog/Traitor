local Lighting = game:GetService("Lighting")
local SettingCallbacks = require(script.Parent.SettingCallbacks)

SettingCallbacks.Listen(function(settingName: string, value: any)
    if settingName ~= "Shadows" then
        return
    end
    
    Lighting.GlobalShadows = value
end)