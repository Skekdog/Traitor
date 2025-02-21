local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Serialisation = require(script.Parent.Serialisation)
local SettingDefinitions = require(script.Parent.SettingDefinitions)
local Settings = require(script.Parent.Settings)
local SettingsUI = require(script.Parent.SettingsUI)

local toLoad: {Settings: string, Version: number} = ReplicatedStorage.ServerClient.LoadSavedSettings.OnClientEvent:Wait()

local function loadSetting(name: string, value: SettingDefinitions.SettingValue)
	Settings.SetSetting(name, value)

	local definition = Settings.GetDefinition(name)
	if not definition.Hidden then
		SettingsUI.AddButton(definition, value)
	end
end

local processedSettings: {string} = {}

if toLoad.Version ~= Settings.SETTINGS_VERSION then
	print(`Settings version mismatched. FromSave: {toLoad.Version}, New: {Settings.SETTINGS_VERSION}`)
else
	local decoded = Serialisation.DeserialiseJSON(toLoad.Settings)

	for i, v in decoded do
		table.insert(processedSettings, i)
		loadSetting(i, v)
	end
end

for i, v in SettingDefinitions do
	assert(v)
	if table.find(processedSettings, i) then
		continue
	end

	loadSetting(i, v.Default)
end

return nil