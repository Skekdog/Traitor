local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Serialisation = require(script.Parent.Serialisation)
local SettingDefinitions = require(script.Parent.SettingDefinitions)
local Settings = require(script.Parent.Settings)

local toLoad: {Settings: string, Version: number} = ReplicatedStorage.ServerClient.LoadSavedSettings.OnClientEvent:Wait()

local function loadSetting(name: string, value: SettingDefinitions.SettingValue)
	if not Settings.GetDefinition(name) then
		return
	end
	Settings.SetSetting(name, value)
end

local processedSettings: {[string]: Settings.SettingValue} = {}

if toLoad.Version ~= Settings.SETTINGS_VERSION then
	print(`Settings version mismatched. FromSave: {toLoad.Version}, New: {Settings.SETTINGS_VERSION}`)
else
	local decoded = Serialisation.DeserialiseJSON(toLoad.Settings)

	for i, v in decoded do
		processedSettings[i] = v
		loadSetting(i, v)
	end
end

for _, v in SettingDefinitions do
	assert(v)
	if processedSettings[v.Name] ~= nil then
		continue
	end

	loadSetting(v.Name, v.Default)
end

Settings.LOADED = true

local SettingsUI = require(script.Parent.SettingsUI)
for _, v in SettingDefinitions do
	assert(v)
	
	if not v.Hidden then
		SettingsUI.AddButton(v, if processedSettings[v.Name] ~= nil then processedSettings[v.Name] else v.Default)
	end
end

require(script.Parent.ExtraButtons)

local UIManager = require(ReplicatedStorage.UIManager)
UIManager.RegisterUI(SettingsUI.UI)

return nil