local SetSidebarAlignment = require(script.Parent.Parent.UIManager.UIScripts.SetSidebarAlignment)
local SettingCallbacks = require(script.Parent.SettingCallbacks)
SettingCallbacks.Listen(function(settingName: string, value: any)
    if settingName ~= "Sidebar Alignment" then
        return
    end
    
    SetSidebarAlignment(value)
end)