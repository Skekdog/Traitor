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

    local mapLighting = map.Map:FindFirstChild("Lighting")
    if mapLighting then
        for i, v in mapLighting:GetChildren() do
            v:Clone().Parent = Lighting
        end
    end

    for i, v in map.Definition.LightingSettings do
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

	alertUI.Object.Text = `Map Loaded: {GetDisplayName(map.Definition)} by {map.Definition.Authors}`
	alertUI:ToggleVisible(true)

	playerlistUI.Object.Info.RoundInfo.Creators.Map.Text = map.Definition.Authors
	playerlistUI.Object.Info.RoundInfo.Info.Map.Text = `Map: {GetDisplayName(map.Definition)}`

	loadLighting(map)

	task.wait(5)
	alertUI:ToggleVisible(false)
end, true)