local SettingCallbacks = require(script.Parent.SettingCallbacks)

SettingCallbacks.Listen(function(settingName: string, value: any)
    if settingName ~= "Keep Shattered Glass" then
        return
    end

    if value then
        return
    end

    for _, v in workspace.Projectiles:GetChildren() do
        if v.Name == "GlassFragment" then
            v:Destroy()
        end
    end
end)