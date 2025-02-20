local SettingDefinitions = require(script.Parent.SettingDefinitions)
local module = {}

export type UpdateControlSettingRequest = {
	Kind: "KeyboardKeybind",
	New: Enum.UserInputType | Enum.KeyCode,
} | {
	Kind: "ControllerKeybind",
	New: Enum.UserInputType | Enum.KeyCode,
} | {
	Kind: "TouchPosition",
	New: UDim2,
} | {
	Kind: "TouchScale",
	New: number,
} | {
	Kind: "Toggled",
	New: boolean,
}

module.SETTINGS_VERSION = 4

local settingValues: {[string]: SettingDefinitions.SettingValue?} = {}

function module.GetDefinition(name: string): SettingDefinitions.SettingDefinition
	return assert(SettingDefinitions[name], `Setting {name} does not exist`)
end

function module.GetSetting(name: string): SettingDefinitions.SettingValue
	local value = settingValues[name]
	assert(value ~= nil, `Setting {name} does not exist`)
	return value
end

function module.SetSetting(name: string, value: SettingDefinitions.SettingValue): ()
	local definition = module.GetDefinition(name)

	assert(typeof(value) == typeof(definition.Default), `Setting {name} must be of type {typeof(definition.Default)}`)

	settingValues[name] = value

	if definition.Callback then
		task.spawn(definition.Callback :: SettingDefinitions.SettingCallback, name, value)
	end
end

function module.UpdateControlSetting(name: string, request: UpdateControlSettingRequest): ()
	local definition = module.GetDefinition(name)

	assert(definition.Kind == "Control", `Setting {name} is not a control setting`)

	local value = module.GetSetting(name) :: SettingDefinitions.ControlValue

	if request.Kind == "KeyboardKeybind" then
		value.Keybind.KBMKeybind = request.New
	elseif request.Kind == "ControllerKeybind" then
		value.Keybind.ConsoleKeybind = request.New
	elseif request.Kind == "TouchPosition" then
		assert(value.TouchButton, `Setting {name} is not a touch setting`)
		value.TouchButton.Position = request.New
	elseif request.Kind == "TouchScale" then
		assert(value.TouchButton, `Setting {name} is not a touch setting`)
		value.TouchButton.Scale = request.New
	elseif request.Kind == "Toggled" then
		assert(definition.SpecifyToggle, `Setting {name} is not a toggle setting`)
		value.Toggled = request.New
	end
end

return module