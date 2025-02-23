local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local IsAdmin = require(ReplicatedStorage.IsAdmin)

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
	Hidden: boolean?,
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

local isLocalAdmin = RunService:IsServer() or IsAdmin(Players.LocalPlayer)

availableSettings.Console = {
	Name = "Console",
	Tab = "Keybinds",
	Hidden = not isLocalAdmin,
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

availableSettings.Shadows = {
	Name = "Shadows",
	Tab = "Display",
	Category = "Environment",
	Tooltip = "Enable or disable global shadows.",
	Kind = "Boolean" :: "Boolean",
	Default = true,

	Callback = function(name, value)
		(require)(callbacks.Shadows)(name, value)
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
		(require)(callbacks.FIBLighting)(name, value)
	end
}

availableSettings["Item Hints"] = {
	Name = "Item Hints",
	Tab = "Display",
	Category = "User Interface",
	Tooltip = "Enables hint text for item controls.",
	Kind = "Boolean" :: "Boolean",
	Default = true,

	Callback = function(name, value)
		(require)(callbacks.ShowItemHints)(name, value)
	end
}

availableSettings["Keep Shattered Glass"] = {
	Name = "Keep Shattered Glass",
	Tab = "Display",
	Category = "Environment",
	Tooltip = "Prevents shattered glass from despawning until the round is over.",
	Kind = "Boolean" :: "Boolean",
	Default = false,

	Callback = function(name, value)
		(require)(callbacks.KeepShatteredGlass)(name, value)
	end
}

availableSettings["Sidebar Alignment"] = {
	Name = "Sidebar Alignment",
	Tab = "Display",
	Category = "User Interface",
	Tooltip = "Left - The sidebar is aligned to the left of the screen.\nRight - The sidebar is aligned to the right of the screen.",
	PossibleValues = {"Left", "Right"},
	Kind = "Choice" :: "Choice",
	Default = "Right",

	Callback = function(name, value)
		(require)(callbacks.SidebarAlignment)(name, value)
	end
}

availableSettings["Always Show Sidebar"] = {
	Name = "Always Show Sidebar",
	Tab = "Display",
	Category = "User Interface",
	Tooltip = "This setting has no effect if a keyboard is not connected.",
	Kind = "Boolean" :: "Boolean",
	Default = true,

	Callback = function(name, value)
		(require)(callbacks.AlwaysShowSidebar)(name, value)
	end
}

availableSettings["Animate UI Transitions"] = {
	Name = "Animate UI Transitions",
	Tab = "Display",
	Category = "User Interface",
	Tooltip = "Controls animation for most UI.",
	Kind = "Boolean" :: "Boolean",
	Default = true,
}

availableSettings["Snap To Ladders"] = {
	Name = "Snap To Ladders",
	Tab = "Gameplay",
	Category = "Gameplay",
	Tooltip = "If enabled, players will snap to ladders when touching. Ladders can still be climbed manually.",
	Kind = "Boolean" :: "Boolean",
	Default = true,
}

availableSettings["Toggle Aim"] = {
	Name = "Toggle Aim",
	Tab = "Gameplay",
	Category = "Gameplay",
	Tooltip = "Determines whether Alternate Fire must be held to aim.",
	Kind = "Boolean" :: "Boolean",
	Default = false,
}

availableSettings["Primary Fire"] = {
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
			Position = UDim2.new(),
			Scale = 1,
		},
	},
}

availableSettings["Alternate Fire"] = {
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
			Position = UDim2.new(),
			Scale = 1,
		},
	},
}

availableSettings["Drop Ammo"] = {
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
		},

		TouchButton = {
			Position = UDim2.new(),
			Scale = 1,
		},
	},
}

availableSettings["Drop"] = {
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
			Position = UDim2.new(),
			Scale = 1,
		},
	},
}

availableSettings["Reload Weapon"] = {
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
			Position = UDim2.new(),
			Scale = 1,
		},
	},
}

availableSettings["Climb Ladder"] = {
	Name = "Climb Ladder",
	Tab = "Keybinds",
	Category = "Gameplay",
	Tooltip = "Used to climb ladders.",
	Kind = "Control" :: "Control",
	SpecifyToggle = false,

	Default = {
		Toggled = true,
		Keybind = {
			KBMKeybind = Enum.KeyCode.E,
		},

		TouchButton = {
			Position = UDim2.new(),
			Scale = 1,
		},
	},
}

availableSettings["Interact"] = {
	Name = "Interact",
	Tab = "Keybinds",
	Category = "Gameplay",
	Tooltip = "Used to interact with objects.",
	Kind = "Control" :: "Control",
	SpecifyToggle = false,

	Default = {
		Toggled = true,
		Keybind = {
			KBMKeybind = Enum.KeyCode.F,
			ConsoleKeybind = Enum.KeyCode.ButtonA,
		},

		TouchButton = {
			Position = UDim2.new(),
			Scale = 1,
		},
	}
}

availableSettings["Close UI"] = {
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
}

availableSettings["Next Item"] = {
	Name = "Next Item",
	Tab = "Keybinds",
	Category = "Inventory",
	Tooltip = "Cycles to the next item. Primarily used for controllers.",
	Kind = "Control" :: "Control",
	SpecifyToggle = false,

	Default = {
		Toggled = true,
		Keybind = {
			ConsoleKeybind = Enum.KeyCode.ButtonY,
		},
	},
}

availableSettings["Slot 1"] = {
	Name = "Slot 1",
	Tab = "Keybinds",
	Category = "Inventory",
	Tooltip = "Equips the item in slot 1.",
	Kind = "Control" :: "Control",
	SpecifyToggle = false,

	Default = {
		Toggled = true,
		Keybind = {
			KBMKeybind = Enum.KeyCode.One,
		},
	},
}

availableSettings["Slot 2"] = {
	Name = "Slot 2",
	Tab = "Keybinds",
	Category = "Inventory",
	Tooltip = "Equips the item in slot 2.",
	Kind = "Control" :: "Control",
	SpecifyToggle = false,

	Default = {
		Toggled = true,
		Keybind = {
			KBMKeybind = Enum.KeyCode.Two,
		},
	},
}

availableSettings["Slot 3"] = {
	Name = "Slot 3",
	Tab = "Keybinds",
	Category = "Inventory",
	Tooltip = "Equips the item in slot 3.",
	Kind = "Control" :: "Control",
	SpecifyToggle = false,

	Default = {
		Toggled = true,
		Keybind = {
			KBMKeybind = Enum.KeyCode.Three,
		},
	},
}

availableSettings["Slot 4"] = {
	Name = "Slot 4",
	Tab = "Keybinds",
	Category = "Inventory",
	Tooltip = "Equips the item in slot 4.",
	Kind = "Control" :: "Control",
	SpecifyToggle = false,

	Default = {
		Toggled = true,
		Keybind = {
			KBMKeybind = Enum.KeyCode.Four,
		},
	},
}

availableSettings["Slot 5"] = {
	Name = "Slot 5",
	Tab = "Keybinds",
	Category = "Inventory",
	Tooltip = "Equips the item in slot 5.",
	Kind = "Control" :: "Control",
	SpecifyToggle = false,

	Default = {
		Toggled = true,
		Keybind = {
			KBMKeybind = Enum.KeyCode.Five,
		},
	},
}

availableSettings["Slot 6"] = {
	Name = "Slot 6",
	Tab = "Keybinds",
	Category = "Inventory",
	Tooltip = "Equips the item in slot 6.",
	Kind = "Control" :: "Control",
	SpecifyToggle = false,

	Default = {
		Toggled = true,
		Keybind = {
			KBMKeybind = Enum.KeyCode.Six,
		},
	},
}

availableSettings["Slot 7"] = {
	Name = "Slot 7",
	Tab = "Keybinds",
	Category = "Inventory",
	Tooltip = "Equips the item in slot 7.",
	Kind = "Control" :: "Control",
	SpecifyToggle = false,

	Default = {
		Toggled = true,
		Keybind = {
			KBMKeybind = Enum.KeyCode.Seven,
		},
	},
}

availableSettings["Slot 8"] = {
	Name = "Slot 8",
	Tab = "Keybinds",
	Category = "Inventory",
	Tooltip = "Equips the item in slot 8.",
	Kind = "Control" :: "Control",
	SpecifyToggle = false,

	Default = {
		Toggled = true,
		Keybind = {
			KBMKeybind = Enum.KeyCode.Eight,
		},
	},
}

availableSettings["Slot 9"] = {
	Name = "Slot 9",
	Tab = "Keybinds",
	Category = "Inventory",
	Tooltip = "Equips the item in slot 9.",
	Kind = "Control" :: "Control",
	SpecifyToggle = false,

	Default = {
		Toggled = true,
		Keybind = {
			KBMKeybind = Enum.KeyCode.Nine,
		},
	},
}

availableSettings["Equipment Shop"] = {
	Name = "Equipment Shop",
	Tab = "Keybinds",
	Category = "Menus - Enable the checkbox to make a keybind toggled",
	Tooltip = "Opens the equipment shop. Only available for certain roles.",
	Kind = "Control" :: "Control",
	SpecifyToggle = true,

	Default = {
		Toggled = true,
		Keybind = {
			KBMKeybind = Enum.KeyCode.C,
			ConsoleKeybind = Enum.KeyCode.DPadUp,
		},
	},
}

availableSettings["Playerlist"] = {
	Name = "Playerlist",
	Tab = "Keybinds",
	Category = "Menus - Enable the checkbox to make a keybind toggled",
	Tooltip = "Opens the playerlist.",
	Kind = "Control" :: "Control",
	SpecifyToggle = true,

	Default = {
		Toggled = false,
		Keybind = {
			KBMKeybind = Enum.KeyCode.Tab,
			ConsoleKeybind = Enum.KeyCode.ButtonL3,
		},
	},
}

availableSettings["Settings"] = {
	Name = "Settings",
	Tab = "Keybinds",
	Category = "Menus - Enable the checkbox to make a keybind toggled",
	Tooltip = "Opens the settings page. Can also be opened by typing !settings in chat.",
	Kind = "Control" :: "Control",
	SpecifyToggle = true,

	Default = {
		Toggled = true,
		Keybind = {
			KBMKeybind = Enum.KeyCode.G,
			ConsoleKeybind = Enum.KeyCode.ButtonR3,
		},
	},
}

availableSettings["Highlights"] = {
	Name = "Highlights",
	Tab = "Keybinds",
	Category = "Menus - Enable the checkbox to make a keybind toggled",
	Tooltip = "Opens the round highlights.",
	Kind = "Control" :: "Control",
	SpecifyToggle = true,

	Default = {
		Toggled = true,
		Keybind = {
			KBMKeybind = Enum.KeyCode.B,
		},
	},
}

return availableSettings