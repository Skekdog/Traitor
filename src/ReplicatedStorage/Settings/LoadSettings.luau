local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Serialisation = require(script.Parent.Serialisation)
local SettingDefinitions = require(script.Parent.SettingDefinitions)
local Settings = require(script.Parent.Settings)
local SettingsUI = require(script.Parent.SettingsUI)

local toLoad: string = ReplicatedStorage.ServerClient.LoadSavedSettings.OnClientEvent:Wait()
local decoded = Serialisation.DeserialiseJSON(toLoad)

local function loadSetting(name: string, value: SettingDefinitions.SettingValue)
	Settings.SetSetting(name, value)
	SettingsUI.AddButton(Settings.GetDefinition(name), value)
end

local processedSettings: {string} = {}

if decoded.SETTINGS_VERSION ~= Settings.SETTINGS_VERSION then
	print(`Settings version mismatched. FromSave: {decoded.SETTINGS_VERSION}, New: {Settings.SETTINGS_VERSION}`)
else
	for i, v in decoded do
		if i == "SETTINGS_VERSION" then
			continue
		end
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