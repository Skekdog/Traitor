local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Serialisation = require(script.Parent.Serialisation)
local SettingDefinitions = require(script.Parent.SettingDefinitions)
local Settings = require(script.Parent.Settings)

local toLoad: string = ReplicatedStorage.ServerClient.LoadSavedSettings.OnClientEvent:Wait()
local loadedVersion: number?

do
	local httpDecoded = HttpService:JSONDecode(toLoad)
	loadedVersion = httpDecoded.SETTINGS_VERSION
end

local function loadSetting(name: string, value: SettingDefinitions.SettingValue)
	if not Settings.GetDefinition(name) then
		return
	end
	Settings.SetSetting(name, value)
end

local processedSettings: {[string]: Settings.SettingValue} = {}

if loadedVersion ~= Settings.SETTINGS_VERSION then
	print(`Settings version mismatched. FromSave: {loadedVersion}, New: {Settings.SETTINGS_VERSION}`)
else
	local decoded = Serialisation.DeserialiseJSON(toLoad)

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

SettingsUI.AdjustForInset(UIManager.GuiInset)

return nil