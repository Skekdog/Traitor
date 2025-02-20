local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local IsAdmin = require(ReplicatedStorage.IsAdmin)

export type KeybindSettingValue = {
	KBMKeybind: Enum.UserInputType | Enum.KeyCode?,
	ConsoleKeybind: Enum.UserInputType | Enum.KeyCode?,
	Toggled: boolean,
}

export type SettingCallback<T = SettingValue> = (name: string, value: T) -> ()

export type BooleanValue = boolean
export type ChoiceValue = string
export type TouchPositionValue = UDim2

export type SettingValue = BooleanValue | ChoiceValue | TouchPositionValue | KeybindSettingValue

export type BaseDefinition = {
	Name: string,
	Tab: string,
	Category: string,
}

export type BooleanDefinition = BaseDefinition & {
	Kind: "Boolean",
	Default: boolean,
	Callback: SettingCallback<boolean>?,
}

export type ChoiceDefinition = BaseDefinition & {
	Kind: "Choice",
	PossibleValues: {string},
	Default: string,
	Callback: SettingCallback<string>?,
}

export type TouchPositionDefinition = BaseDefinition & {
	Kind: "TouchPosition",
	Default: UDim2,
	Callback: SettingCallback<UDim2>?,
}

export type KeybindDefinition = BaseDefinition & {
	Kind: "Keybind",
	Default: KeybindSettingValue,
	Callback: SettingCallback<KeybindSettingValue>?,
}

export type SettingDefinition = BooleanDefinition | ChoiceDefinition | TouchPositionDefinition | KeybindDefinition

local callbacks = script.Parent.Callbacks
local availableSettings: {[string]: SettingDefinition?} = {}

if false and IsAdmin(Players.LocalPlayer) then
	availableSettings.Console = {
		Name = "Console",
		Tab = "Keybinds",
		Category = "Menus - Enable the checkbox to make a keybind toggled",
		Tooltip = "Opens the console.",
		Kind = "Keybind" :: "Keybind",
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
	Kind = "Boolean" :: "Boolean",
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
	Kind = "Boolean" :: "Boolean",
	Default = false,

	Callback = function(name, value)
		require(callbacks.FIBLighting)(name, value)
	end
}

availableSettings["Background Menus"] = {
	Name = "Background Menus",
	Tab = "Display",
	Category = "User Interface",
	Tooltip = "Closed - Menus are closed when another is opened.\nStacked - Menus remain open when another is opened.",
	PossibleValues = {"Closed", "Stacked"},
	Kind = "Choice" :: "Choice",
	Default = "Closed",
}

return availableSettings