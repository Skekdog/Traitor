local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local IsAdmin = require(ReplicatedStorage.IsAdmin)

export type ControlValue = {
	Toggled: boolean,
	Keybind: {
		KBMKeybind: Enum.UserInputType | Enum.KeyCode?,
		ConsoleKeybind: Enum.UserInputType | Enum.KeyCode?,
	},

	TouchButton: {
		Enabled: boolean,
		Position: UDim2,
		Scale: number,
	}?,
}

export type SettingCallback<T = SettingValue> = (name: string, value: T) -> ()

export type BooleanValue = boolean
export type ChoiceValue = string
export type TouchPositionValue = UDim2

export type SettingValue = BooleanValue | ChoiceValue | ControlValue

export type BaseDefinition = {
	Name: string,
	Tab: string,
	Category: string,
}

export type BooleanDefinition = BaseDefinition & {
	Kind: "Boolean",
	Default: BooleanValue,
	Callback: SettingCallback<BooleanValue>?,
}

export type ChoiceDefinition = BaseDefinition & {
	Kind: "Choice",
	PossibleValues: {ChoiceValue},
	Default: ChoiceValue,
	Callback: SettingCallback<ChoiceValue>?,
}

export type ControlDefinition = BaseDefinition & {
	Kind: "Control",
	Default: ControlValue,
	SpecifyToggle: boolean?,
	Callback: SettingCallback<ControlValue>?,
}

export type SettingDefinition = BooleanDefinition | ChoiceDefinition | ControlDefinition

local callbacks = script.Parent.Callbacks
local availableSettings: {[string]: SettingDefinition?} = {}

if IsAdmin(Players.LocalPlayer) then
	availableSettings.Console = {
		Name = "Console",
		Tab = "Keybinds",
		Category = "Menus - Enable the checkbox to make a keybind toggled",
		Tooltip = "Opens the console.",
		Kind = "Control" :: "Control",
		Default = {
			Toggled = true,
			Keybind = {
				KBMKeybind = Enum.KeyCode.Backquote,
			},
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