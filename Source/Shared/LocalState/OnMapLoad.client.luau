local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GetDisplayName = require(ReplicatedStorage.Shared.RoundRule.Common.GetDisplayName)
local LocalRoundInfo = require(script.Parent.LocalRoundInfo)
local UIManager = require(ReplicatedStorage.Shared.Interface.UILib.UIManager)
local Types = require(ReplicatedStorage.Shared.RoundRule.Types)

local knownLightingSettings: {string} = {}

local alertUI = UIManager.WaitForUI("Alert") :: UIManager.UI & {Object: typeof(UIManager.UnregisteredUIs.Alert)}
local playerlistUI = UIManager.WaitForUI("Playerlist") :: UIManager.UI & {Object: typeof(UIManager.UnregisteredUIs.Playerlist)}

local function loadLighting(map: Types.Map): ()
	for _, v in Lighting:GetChildren() do
        if not v:GetAttribute("IgnoreLighting") then
            v:Destroy()
        end
    end

    for _, v in knownLightingSettings do
        Lighting:ResetPropertyToDefault(v)
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
end

LocalRoundInfo.Map:Connect(function(map)
	if not map then
		return
	end

	alertUI.Object.Text = `Map Loaded: {GetDisplayName(map)} by {map.Authors}`
	alertUI:ToggleVisible(true)

	playerlistUI.Object.Info.RoundInfo.Creators.Map.Text = map.Authors
	playerlistUI.Object.Info.RoundInfo.Info.Map.Text = `Map: {GetDisplayName(map)}`

	loadLighting(map)

	task.wait(5)
	alertUI:ToggleVisible(false)
end, true)