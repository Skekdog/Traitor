local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local IsAdmin = require(ReplicatedStorage.IsAdmin)

export type KeybindSettingValue = {
	KBMKeybind: Enum.UserInputType | Enum.KeyCode?,
	ConsoleKeybind: Enum.UserInputType | Enum.KeyCode?,
	Toggled: boolean,
}

export type SettingCallback<T = SettingValue> = (name: string, value: T) -> ()

export type SettingValue = string | boolean | UDim2 | KeybindSettingValue

export type SettingDefinition = {
	Name: string,
	Tab: string,
	Category: string,
} & ({
	PossibleValues: "Boolean",
	Default: boolean,
	Callback: SettingCallback<boolean>?,
} | {
	PossibleValues: {string},
	Default: string,
	Callback: SettingCallback<string>?,
} | {
	PossibleValues: "TouchPosition",
	Default: UDim2,
	Callback: SettingCallback<UDim2>?,
} | {
	PossibleValues: "Keybind",
	Default: KeybindSettingValue,
	Callback: SettingCallback<KeybindSettingValue>?,
})

local module = {}

module.SETTINGS_VERSION = 4

local callbacks = script.Parent.Callbacks

local availableSettings: {[string]: SettingDefinition?} = {}
local settings: {[string]: SettingValue?} = {}

function module.GetSetting(name: string): SettingValue
	return assert(settings[name], `Setting {name} does not exist`)
end

function module.SetSetting(name: string, value: SettingValue): ()
	local definition = availableSettings[name]

	assert(definition, `Setting {name} does not exist`)
	assert(typeof(value) == typeof(definition.Default), `Setting {name} must be of type {typeof(definition.Default)}`)

	settings[name] = value

	if definition.Callback then
		task.spawn(definition.Callback :: SettingCallback, name, value)
	end
end

if IsAdmin(Players.LocalPlayer) then
	availableSettings.Console = {
		Name = "Console",
		Tab = "Keybinds",
		Category = "Menus - Enable the checkbox to make a keybind toggled",
		Tooltip = "Opens the console.",
		PossibleValues = "Keybind" :: "Keybind",
		Default = {
			KBMKeybind = Enum.KeyCode.Backquote,
			Toggled = true,
		},
	}
end

availableSettings.Shadows = {
	Name = "Shadows",
	Tab = "Display",
	Category = "Environment",
	Tooltip = "Enable or disable global shadows.",
	PossibleValues = "Boolean" :: "Boolean",
	Default = true,

	Callback = function(name, value)
		require(callbacks.Shadows)(name, value)
	end,
}

availableSettings["Use FIB Lighting"] = {
	Name = "Use FIB Lighting",
	Tab = "Display",
	Category = "Environment",
	Tooltip = "If you have modified your client to use Future lighting, enable this for better map compatibility.",
	PossibleValues = "Boolean" :: "Boolean",
	Default = false,

	Callback = function(name, value)
		require(callbacks.FIBLighting)(name, value)
	end
}

module.AvailableSettings = availableSettings

return module