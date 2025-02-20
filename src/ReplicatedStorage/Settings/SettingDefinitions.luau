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

local callbacks = script.Parent.Callbacks
local availableSettings: {[string]: SettingDefinition?} = {}

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

return availableSettings