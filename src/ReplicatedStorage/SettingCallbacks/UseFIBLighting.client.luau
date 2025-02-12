local Lighting = game:GetService("Lighting")
local LocalRoundInfo = require(script.Parent.Parent.LocalRoundInfo)
local SettingCallbacks = require(script.Parent.SettingCallbacks)

SettingCallbacks.Listen(function(settingName: string, value: any)
    if settingName ~= "Use FIB Lighting" then
        return
    end
    
    local map = LocalRoundInfo.GetMap()
    if not map then
        return
    end

    Lighting:ClearAllChildren()
    if value then
        for _, v in map.FutureLightingModifiers:GetChildren() do
            v:Clone().Parent = Lighting
        end
    end

    for _, v in map.LightingModifiers:GetChildren() do
        if not Lighting:FindFirstChildOfClass(v.ClassName) then
            v:Clone().Parent = Lighting
        end
    end

    for i, v in map.LightingSettings do
        (Lighting :: any)[i] = v
    end

    if value then
        for i, v in map.FutureLightingSettings do
            (Lighting :: any)[i] = v
        end
    end
end)