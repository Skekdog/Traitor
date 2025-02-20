local SettingDefinitions = require(script.Parent.SettingDefinitions)
local module = {}

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

return module