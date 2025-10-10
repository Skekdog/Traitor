local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local RelaxedPermissions = require(ReplicatedStorage.Shared.DevTools.RelaxedPermissions)
local IsAdmin = require(ReplicatedStorage.Shared.DevTools.IsAdmin)

export type ControlValue = {
	Toggled: boolean,
	Keybind: {
		KBMKeybind: Enum.UserInputType | Enum.KeyCode?,
		ConsoleKeybind: Enum.UserInputType | Enum.KeyCode?,
	},

	TouchButton: {
		Position: UDim2,
		Scale: number,
	}?,
}

export type SettingCallback<T = SettingValue> = (name: string, value: T) -> ()

export type BooleanValue = boolean
export type ChoiceValue = string

export type SettingValue = BooleanValue | ChoiceValue | ControlValue

export type BaseDefinition = {
	Name: string,
	Tab: string,
	Category: string,
	Tooltip: string?,
	Hidden: boolean?,
	IgnoreInvalidChoice: boolean?,
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
local availableSettings: {SettingDefinition} = {}

local isLocalAdmin = RunService:IsServer() or IsAdmin(Players.LocalPlayer) or RelaxedPermissions.HasRelaxedPermissions(Players.LocalPlayer)

table.insert(availableSettings, {
	Name = "Chat Tag",
	Tab = "Display",
	Category = "Chat",
	Kind = "Choice" :: "Choice",
	PossibleValues = {"None"},
	Default = "None",
	IgnoreInvalidChoice = true,

	Callback = function(name, value)
		(require)(callbacks.ChatTag)(name, value)
	end
})

table.insert(availableSettings, {
	Name = "Shadows",
	Tab = "Display",
	Category = "Environment",
	Kind = "Boolean" :: "Boolean",
	Default = true,

	Callback = function(name, value)
		(require)(callbacks.Shadows)(name, value)
	end,
})

table.insert(availableSettings, {
	Name = "Item Hints",
	Tab = "Display",
	Category = "User Interface",
	Tooltip = "Enables hint text for equipped item controls.",
	Kind = "Boolean" :: "Boolean",
	Default = true,

	Callback = function(name, value)
		(require)(callbacks.ShowItemHints)(name, value)
	end
})

table.insert(availableSettings, {
	Name = "Keep Shattered Glass",
	Tab = "Display",
	Category = "Environment",
	Tooltip = "Prevents shattered glass from despawning until the round is over.",
	Kind = "Boolean" :: "Boolean",
	Default = false,

	Callback = function(name, value)
		(require)(callbacks.KeepShatteredGlass)(name, value)
	end
})

table.insert(availableSettings, {
	Name = "Sidebar Alignment",
	Tab = "Display",
	Category = "User Interface",
	PossibleValues = {"Left", "Right"},
	Kind = "Choice" :: "Choice",
	Default = "Right",

	Callback = function(name, value)
		(require)(callbacks.SidebarAlignment)(name, value)
	end
})

table.insert(availableSettings, {
	Name = "Show Hit Rejects",
	Tab = "Display",
	Category = "Debug",
	Kind = "Boolean" :: "Boolean",
	Default = false,
	Tooltip = "Display an on-screen warning when a hit is rejected.",
})

table.insert(availableSettings, {
	Name = "Animate UI Transitions",
	Tab = "Display",
	Category = "User Interface",
	Tooltip = "Controls animation for most UI.",
	Kind = "Boolean" :: "Boolean",
	Default = true,
})

table.insert(availableSettings, {
	Name = "Snap To Ladders",
	Tab = "Gameplay",
	Category = "Gameplay",
	Tooltip = "If enabled, touching a ladder will automatically begin climbing it. You can still climb ladders manually.",
	Kind = "Boolean" :: "Boolean",
	Default = true,
})

table.insert(availableSettings, {
	Name = "Quick Chat",
	Tab = "Keybinds",
	Category = "Chat",
	Kind = "Control" :: "Control",
	SpecifyToggle = false,

	Default = {
		Toggled = true,
		Keybind = {
			KBMKeybind = Enum.KeyCode.V,
		},
	},

	Callback = function(name: string, value: ControlValue)
		(require)(callbacks.Keybind)(name, value)
	end,
})

table.insert(availableSettings, {
	Name = "Crouch",
	Tab = "Keybinds",
	Category = "Movement",
	Kind = "Control" :: "Control",
	Tooltip = "Also used for covert corpse searching.",
	SpecifyToggle = false,

	Default = {
		Toggled = true,
		Keybind = {
			KBMKeybind = Enum.KeyCode.LeftControl,
			ConsoleKeybind = Enum.KeyCode.ButtonR3,
		},

		TouchButton = {
			Position = UDim2.fromScale(0.15, 0.5),
			Scale = 1,
		},
	},

	Callback = function(name: string, value: ControlValue)
		(require)(callbacks.Keybind)(name, value)
	end,
})

table.insert(availableSettings, {
	Name = "Primary Fire",
	Tab = "Keybinds",
	Category = "Items",
	Tooltip = "For using weapons or planting equipment.",
	Kind = "Control" :: "Control",
	SpecifyToggle = false,

	Default = {
		Toggled = false,
		Keybind = {
			KBMKeybind = Enum.UserInputType.MouseButton1,
			ConsoleKeybind = Enum.KeyCode.ButtonR2,
		},

		TouchButton = {
			Position = UDim2.fromScale(0.05, 0.2),
			Scale = 2,
		},
	},

	Callback = function(name: string, value: ControlValue)
		(require)(callbacks.Keybind)(name, value)
	end,
})

table.insert(availableSettings, {
	Name = "Alternate Fire",
	Tab = "Keybinds",
	Category = "Items",
	Tooltip = "For aiming weapons or using the alternate item function.",
	Kind = "Control" :: "Control",
	SpecifyToggle = false,

	Default = {
		Toggled = false,
		Keybind = {
			KBMKeybind = Enum.UserInputType.MouseButton2,
			ConsoleKeybind = Enum.KeyCode.ButtonL2,
		},

		TouchButton = {
			Position = UDim2.fromScale(0.15, 0.2),
			Scale = 1,
		},
	},

	Callback = function(name: string, value: ControlValue)
		(require)(callbacks.Keybind)(name, value)
	end,
})

table.insert(availableSettings, {
	Name = "Drop Ammo",
	Tab = "Keybinds",
	Category = "Items",
	Tooltip = "Empties the ammo of the currently equipped weapon into a box. Not all weapons can be emptied.",
	Kind = "Control" :: "Control",
	SpecifyToggle = false,

	Default = {
		Toggled = true,
		Keybind = {
			KBMKeybind = Enum.KeyCode.Z,
			ConsoleKeybind = Enum.KeyCode.DPadRight,
		},

		TouchButton = {
			Position = UDim2.fromScale(0.05, 0.55),
			Scale = 1,
		},
	},

	Callback = function(name: string, value: ControlValue)
		(require)(callbacks.Keybind)(name, value)
	end,
})

table.insert(availableSettings, {
	Name = "Drop",
	Tab = "Keybinds",
	Category = "Items",
	Tooltip = "Drops the currently equipped item. Not all items can be dropped.",
	Kind = "Control" :: "Control",
	SpecifyToggle = false,

	Default = {
		Toggled = true,
		Keybind = {
			KBMKeybind = Enum.KeyCode.Q,
			ConsoleKeybind = Enum.KeyCode.DPadDown,
		},

		TouchButton = {
			Position = UDim2.fromScale(0.05, 0.45),
			Scale = 1,
		},
	},

	Callback = function(name: string, value: ControlValue)
		(require)(callbacks.Keybind)(name, value)
	end,
})

table.insert(availableSettings, {
	Name = "Reload Weapon",
	Tab = "Keybinds",
	Category = "Items",
	Tooltip = "Reloads the currently equipped weapon.",
	Kind = "Control" :: "Control",
	SpecifyToggle = false,

	Default = {
		Toggled = true,
		Keybind = {
			KBMKeybind = Enum.KeyCode.R,
			ConsoleKeybind = Enum.KeyCode.ButtonX,
		},

		TouchButton = {
			Position = UDim2.fromScale(0.05, 0.35),
			Scale = 1,
		},
	},

	Callback = function(name: string, value: ControlValue)
		(require)(callbacks.Keybind)(name, value)
	end,
})

table.insert(availableSettings, {
	Name = "Flashlight",
	Tab = "Keybinds",
	Category = "Gameplay",
	Tooltip = "Toggles the flashlight which you always have on your character.",
	Kind = "Control" :: "Control",
	SpecifyToggle = false,

	Default = {
		Toggled = true,
		Keybind = {
			KBMKeybind = Enum.KeyCode.F,
			ConsoleKeybind = Enum.KeyCode.ButtonL1,
		},

		TouchButton = {
			Position = UDim2.fromScale(0.15, 0.4),
			Scale = 1,
		},
	},

	Callback = function(name: string, value: ControlValue)
		(require)(callbacks.Keybind)(name, value)
	end,
})

table.insert(availableSettings, {
	Name = "Interact",
	Tab = "Keybinds",
	Category = "Gameplay",
	Tooltip = "Used to interact with most objects.",
	Kind = "Control" :: "Control",
	SpecifyToggle = false,

	Default = {
		Toggled = false,
		Keybind = {
			KBMKeybind = Enum.KeyCode.E,
			ConsoleKeybind = Enum.KeyCode.ButtonA,
		},

		TouchButton = {
			Position = UDim2.fromScale(0.15, 0.3),
			Scale = 1,
		},
	},

	Callback = function(name: string, value: ControlValue)
		(require)(callbacks.Keybind)(name, value)
	end,
})

table.insert(availableSettings, {
	Name = "Next Item",
	Tab = "Keybinds",
	Category = "Inventory",
	Tooltip = "Cycles to the next item. Primarily used with controllers.",
	Kind = "Control" :: "Control",
	SpecifyToggle = false,

	Default = {
		Toggled = true,
		Keybind = {
			ConsoleKeybind = Enum.KeyCode.ButtonY,
		},
	},

	Callback = function(name: string, value: ControlValue)
		(require)(callbacks.Keybind)(name, value)
	end,
})

table.insert(availableSettings, {
	Name = "Close UI",
	Tab = "Keybinds",
	Category = "Menus",
	Tooltip = "Closes the fore-most UI.",
	Kind = "Control" :: "Control",
	SpecifyToggle = false,

	Default = {
		Toggled = true,
		Keybind = {
			KBMKeybind = Enum.KeyCode.X,
			ConsoleKeybind = Enum.KeyCode.ButtonB,
		},
	},

	Callback = function(name: string, value: ControlValue)
		(require)(callbacks.Keybind)(name, value)
	end,
})

table.insert(availableSettings, {
	Name = "Console",
	Tab = "Keybinds",
	Hidden = not isLocalAdmin,
	Category = "Menus",
	Kind = "Control" :: "Control",
	SpecifyToggle = false,
	Default = {
		Toggled = true,
		Keybind = {
			KBMKeybind = Enum.KeyCode.Backquote,
		},
	},

	Callback = function(name: string, value: ControlValue)
		(require)(callbacks.Keybind)(name, value)
	end,
})

table.insert(availableSettings, {
	Name = "Equipment Shop",
	Tab = "Keybinds",
	Category = "Menus - Enable the checkbox to make a keybind toggled",
	Tooltip = "Opens the Equipment Shop. Only certain roles have access to the Equipment Shop.",
	Kind = "Control" :: "Control",
	SpecifyToggle = true,

	Default = {
		Toggled = true,
		Keybind = {
			KBMKeybind = Enum.KeyCode.C,
			ConsoleKeybind = Enum.KeyCode.DPadUp,
		},
	},

	Callback = function(name: string, value: ControlValue)
		(require)(callbacks.Keybind)(name, value)
	end,
})

table.insert(availableSettings, {
	Name = "Playerlist",
	Tab = "Keybinds",
	Category = "Menus - Enable the checkbox to make a keybind toggled",
	Kind = "Control" :: "Control",
	SpecifyToggle = true,

	Default = {
		Toggled = false,
		Keybind = {
			KBMKeybind = Enum.KeyCode.Tab,
			ConsoleKeybind = Enum.KeyCode.ButtonL3,
		},
	},

	Callback = function(name: string, value: ControlValue)
		(require)(callbacks.Keybind)(name, value)
	end,
})

table.insert(availableSettings, {
	Name = "Settings",
	Tab = "Keybinds",
	Category = "Menus - Enable the checkbox to make a keybind toggled",
	Kind = "Control" :: "Control",
	SpecifyToggle = true,

	Default = {
		Toggled = true,
		Keybind = {
			KBMKeybind = Enum.KeyCode.G,
			ConsoleKeybind = Enum.KeyCode.DPadLeft,
		},
	},

	Callback = function(name: string, value: ControlValue)
		(require)(callbacks.Keybind)(name, value)
	end,
})

table.insert(availableSettings, {
	Name = "Highlights",
	Tab = "Keybinds",
	Category = "Menus - Enable the checkbox to make a keybind toggled",
	Kind = "Control" :: "Control",
	SpecifyToggle = true,

	Default = {
		Toggled = true,
		Keybind = {
			KBMKeybind = Enum.KeyCode.B,
		},
	},

	Callback = function(name: string, value: ControlValue)
		(require)(callbacks.Keybind)(name, value)
	end,
})

local numberNames = {"One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine"}

for i = 1, 9 do
	table.insert(availableSettings, {
		Name = "Slot " .. tostring(i),
		Tab = "Keybinds",
		Category = "Inventory",
		Kind = "Control" :: "Control",
		SpecifyToggle = false,

		Default = {
			Toggled = true,
			Keybind = {
				KBMKeybind = (Enum.KeyCode :: any)[numberNames[i]],
			},
		},

		Callback = function(name: string, value: ControlValue)
			(require)(callbacks.Keybind)(name, value)
		end,
	})
end

for i = 1, 9 do
	table.insert(availableSettings, {
		Name = "Quick Chat " .. tostring(i),
		Tab = "Keybinds",
		Category = "Chat",
		Kind = "Control" :: "Control",
		SpecifyToggle = false,

		Default = {
			Toggled = true,
			Keybind = {
				KBMKeybind = (Enum.KeyCode :: any)[numberNames[i]]
			}
		},

		Callback = function(name: string, value: ControlValue)
			(require)(callbacks.Keybind)(name, value)
		end,
	})
end

return availableSettings