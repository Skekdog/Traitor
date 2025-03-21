local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Serialisation = require(script.Parent.Serialisation)
local SettingDefinitions = require(script.Parent.SettingDefinitions)
local Settings = require(script.Parent.Settings)

local values: {[string]: SettingDefinitions.SettingValue} = {}

local function setSetting(name: string, value: SettingDefinitions.SettingValue): ()
	if not Settings.GetDefinition(name) then
		return
	end

	values[name] = value
	Settings.SetSetting(name, value)
end

for _, v in SettingDefinitions do
	setSetting(v.Name, v.Default)
end
Settings.LOADED = true

ReplicatedStorage.ServerClient.LoadSavedSettings.OnClientEvent:Connect(function(toLoad: string): ()
	local loadedVersion: number?

	do
		local httpDecoded = HttpService:JSONDecode(toLoad)
		loadedVersion = httpDecoded.SETTINGS_VERSION
	end

	if loadedVersion == Settings.SETTINGS_VERSION then
		local decoded = Serialisation.DeserialiseJSON(toLoad)
	
		for i, v in decoded do
			setSetting(i, v)
		end
	end

	local SettingsUI = require(script.Parent.SettingsUI)
	for i, v in SettingDefinitions do
		if not v.Hidden then
			SettingsUI.AddButton(v, values[v.Name])
		end
	end

	require(script.Parent.ExtraButtons)

	local UIManager = require(ReplicatedStorage.UIManager)
	UIManager.RegisterUI(SettingsUI.UI)

	SettingsUI.AdjustForInset(UIManager.GuiInset)
end)

return nil