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

Settings.LOADED = true

ReplicatedStorage.Remotes.ServerClient.LoadSavedSettings.OnClientEvent:Connect(function(toLoad: string): ()
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
			local value = values[v.Name]
			if value == nil then
				value = v.Default
			end
			assert(value ~= nil, "Value must not be nil")
			SettingsUI.AddButton(v, value)
		end
	end

	require(script.Parent.ExtraButtons)

	local UIManager = require(ReplicatedStorage.Shared.Interface.UILib.UIManager)
	UIManager.RegisterUI(SettingsUI.UI)

	SettingsUI.AdjustForInset(UIManager.GuiInset)

	require(script.Parent.ChatTagSetting)
end)

return nil