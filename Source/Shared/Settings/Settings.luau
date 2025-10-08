local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Serialisation = require(script.Parent.Serialisation)
local SettingDefinitions = require(script.Parent.SettingDefinitions)
local module = {}

export type UpdateControlSettingRequest = {
	Kind: "KeyboardKeybind",
	New: Enum.UserInputType | Enum.KeyCode?,
} | {
	Kind: "ControllerKeybind",
	New: Enum.UserInputType | Enum.KeyCode?,
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

export type BooleanValue = SettingDefinitions.BooleanValue
export type ChoiceValue = SettingDefinitions.ChoiceValue
export type ControlValue = SettingDefinitions.ControlValue
export type SettingValue = SettingDefinitions.SettingValue

module.SETTINGS_VERSION = 7
module.LOADED = false

local function yieldIfNotLoaded(): ()
	while not module.LOADED do
		task.wait()
	end
end

local settingValues: {[string]: SettingDefinitions.SettingValue?, SETTINGS_VERSION: number} = {SETTINGS_VERSION = module.SETTINGS_VERSION}

function module.GetDefinition(name: string): SettingDefinitions.SettingDefinition?
	for _, definition in SettingDefinitions do
		if definition.Name == name then
			return definition
		end
	end

	return nil
end

function module.GetSetting(name: string): SettingDefinitions.SettingValue
	yieldIfNotLoaded()
	local value = if settingValues[name] ~= nil then settingValues[name] else (module.GetDefinition(name) or {Default = nil}).Default
	assert(value ~= nil, `No value found for setting {name}`)
	return value
end

function module.SetSetting(name: string, value: SettingDefinitions.SettingValue): ()
	local definition = module.GetDefinition(name)
	assert(definition, `Setting {name} does not exist`)

	if definition.Kind == "Boolean" then
		assert(typeof(value) == "boolean", `Setting {name} must be of type boolean`)
	elseif definition.Kind == "Choice" then
		assert(typeof(value) == "string", `Setting {name} must be of type string`)
		assert(definition.IgnoreInvalidChoice or table.find(definition.PossibleValues, value), `Setting {name} must be one of: {table.concat(definition.PossibleValues, ", ")}`)
	elseif definition.Kind == "Control" then
		assert(typeof(value) == "table", `Setting {name} must be of type table`)
	end

	settingValues[name] = value

	if definition.Callback then
		task.spawn(definition.Callback :: SettingDefinitions.SettingCallback, name, value)
	end
end

function module.ResetAll(): {[SettingDefinitions.SettingDefinition]: SettingDefinitions.SettingValue}
	local reset: {[SettingDefinitions.SettingDefinition]: SettingDefinitions.SettingValue} = {}
	for name, _ in settingValues do
		if name == "SETTINGS_VERSION" then
			continue
		end

		local definition = module.GetDefinition(name)
		assert(definition, `Setting {name} does not exist`)

		reset[definition] = definition.Default

		module.SetSetting(name, definition.Default)
	end
	settingValues = {SETTINGS_VERSION = module.SETTINGS_VERSION}

	return reset
end

function module.UpdateControlSetting(name: string, request: UpdateControlSettingRequest): ()
	local definition = module.GetDefinition(name)

	assert(definition, `Setting {name} does not exist`)
	assert(definition.Kind == "Control", `Setting {name} is not a control setting`)

	local value = module.GetSetting(name) :: SettingDefinitions.ControlValue
	value = {
		Keybind = {
			KBMKeybind = value.Keybind.KBMKeybind,
			ConsoleKeybind = value.Keybind.ConsoleKeybind,
		},
		Toggled = value.Toggled,
		TouchButton = if value.TouchButton then {
			Position = value.TouchButton.Position,
			Scale = value.TouchButton.Scale,
		} else nil,
	}

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

	module.SetSetting(name, value)
end

function module.JSONEncode(): string
	local encoded = Serialisation.SerialiseTable(settingValues)
	return encoded
end

function module.SaveSettings(): ()
	assert(RunService:IsClient(), "SaveSettings should only be called from the client")
	ReplicatedStorage.Remotes.ClientServer.SaveSettings:FireServer(module.JSONEncode())
end

return module