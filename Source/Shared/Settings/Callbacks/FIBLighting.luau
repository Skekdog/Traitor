local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalRoundInfo = require(ReplicatedStorage.Shared.LocalState.LocalRoundInfo)

local knownLightingSettings: {string} = {}

return function(name: string, value: boolean): ()
	local map = LocalRoundInfo.Map()
    if not map then
        return
    end

    for _, v in Lighting:GetChildren() do
        if not v:GetAttribute("IgnoreLighting") then
            v:Destroy()
        end
    end

    for _, v in knownLightingSettings do
        Lighting:ResetPropertyToDefault(v)
    end

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
        if not table.find(knownLightingSettings, i) then
            table.insert(knownLightingSettings, i)
        end
    end

    if value then
        for i, v in map.FutureLightingSettings do
            (Lighting :: any)[i] = v
            if not table.find(knownLightingSettings, i) then
                table.insert(knownLightingSettings, i)
            end
        end
    end
end