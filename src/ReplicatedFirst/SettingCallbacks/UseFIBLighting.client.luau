local Lighting = game:GetService("Lighting")
local LocalRoundInfo = require(script.Parent.Parent.LocalRoundInfo)
local Types = require(script.Parent.Parent.RoundHandler.Types)
local SettingCallbacks = require(script.Parent.SettingCallbacks)

SettingCallbacks.Listen(function(settingName: string, value: any)
    if settingName ~= "Use FIB Lighting" then
        return
    end
    
    local map = LocalRoundInfo.GetMap()
    if not map then
        return
    end

    local mapConfig: Types.LightingStructure?
    if value then
        mapConfig = map.Map:FindFirstChild("FIBLighting") :: Types.LightingStructure?
    else
        mapConfig = map:FindFirstChild("Lighting") :: Types.LightingStructure?
    end
    if mapConfig then
        for _, prop in mapConfig:GetChildren() do
            if prop:IsA("ValueBase") then
                (Lighting :: any)[prop.Name] = (prop :: any).Value
            end
        end
    end
end)