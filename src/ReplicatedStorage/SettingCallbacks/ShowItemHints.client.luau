local ItemHint = require(script.Parent.Parent.ItemHint)
local SettingCallbacks = require(script.Parent.SettingCallbacks)

SettingCallbacks.Listen(function(settingName: string, value: any)
    if settingName ~= "Show Item Hints" then
        return
    end
    
    if not value then
        ItemHint()
    end
end)
