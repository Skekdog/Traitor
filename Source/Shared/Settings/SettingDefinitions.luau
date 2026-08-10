local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local VoiceChatService = game:GetService("VoiceChatService")
local RelaxedPermissions = require(ReplicatedStorage.Shared.DevTools.RelaxedPermissions)
local IsAdmin = require(ReplicatedStorage.Shared.DevTools.IsAdmin)

export type ControlValue = {
	Toggled: boolean,
	LongHoldGamepad: boolean?,
	Keybind: {
		KBMKeybind: Enum.UserInputType | Enum.KeyCode?,
		Gamepad: Enum.UserInputType | Enum.KeyCode?,
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
	Callback: SettingCallback<ControlValue>,
}

export type SettingDefinition = BooleanDefinition | ChoiceDefinition | ControlDefinition

local callbacks = script.Parent.Callbacks
local availableSettings: {SettingDefinition} = {}

local isLocalAdmin = RunService:IsServer() or IsAdmin(Players.LocalPlayer) or RelaxedPermissions.HasRelaxedPermissions(Players.LocalPlayer)
local isVcEnabled = RunService:IsServer() or VoiceChatService:IsVoiceEnabledForUserIdAsync(Players.LocalPlayer.UserId)

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
	Name = "Hide Padlocked Chat",
	Tab = "Display",
	Category = "Chat",
	Kind = "Boolean" :: "Boolean",
	Default = false,

	Tooltip = "When disabled, chat messages from incompatible age groups will be censored. When enabled, those chat messages will be entirely hidden."
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
	Name = "Always Show Sidebar",
	Tab = "Display",
	Category = "User Interface",
	Tooltip = "The sidebar is always visible when using touchscreen, or if you very intelligently decide to unbind the settings menu.",
	Kind = "Boolean" :: "Boolean",
	Default = true,

	Callback = function(name, value)
		(require)(callbacks.AlwaysShowSidebar).Callback(name, value)
	end
})

table.insert(availableSettings, {
	Name = "Animate UI",
	Tab = "Display",
	Category = "User Interface",
	Tooltip = "If 'Reduce Motion' is enabled in Roblox settings, this setting is ignored. Otherwise, this will disable most UI animation.",
	Kind = "Boolean" :: "Boolean",
	Default = true,
})

table.insert(availableSettings, {
	Name = "Show Hit Rejects",
	Tab = "Display",
	Category = "Debug",
	Kind = "Boolean" :: "Boolean",
	Default = RunService:IsStudio(),
	Tooltip = "Display an on-screen warning when a hit is rejected.",
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
	Name = "Auto-Jump",
	Tab = "Gameplay",
	Category = "Gameplay",
	Tooltip = "Only has an effect on mobile devices.",
	Kind = "Boolean" :: "Boolean",
	Default = false,

	Callback = function(name: string, value: boolean): ()
		(require)(callbacks.AutoJump)(name, value)
	end
})

table.insert(availableSettings, {
	Name = "Listen To Self",
	Tab = "Gameplay",
	Category = "Audio",
	Tooltip = "When active, you will hear your own voice chat.",
	Kind = "Boolean" :: "Boolean",
	Hidden = not isVcEnabled,
	Default = false,

	Callback = function(name: string, value: boolean): ()
		(require)(callbacks.ListenToSelf)(name, value)
	end
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
			Gamepad = Enum.KeyCode.ButtonB,
		},

		TouchButton = {
			Position = UDim2.fromScale(0.775, 0.75),
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
			Gamepad = Enum.KeyCode.ButtonR2,
		},

		TouchButton = {
			Position = UDim2.fromScale(0.9, 0.25),
			Scale = 2.5,
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
			Gamepad = Enum.KeyCode.ButtonL2,
		},

		TouchButton = {
			Position = UDim2.fromScale(0.775, 0.2),
			Scale = 1.75,
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
		LongHoldGamepad = true,
		Keybind = {
			KBMKeybind = Enum.KeyCode.Z,
			Gamepad = Enum.KeyCode.DPadDown,
		},

		TouchButton = {
			Position = UDim2.fromScale(0.858, 0.45),
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
			Gamepad = Enum.KeyCode.DPadDown,
		},

		TouchButton = {
			Position = UDim2.fromScale(0.925, 0.45),
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
			Gamepad = Enum.KeyCode.ButtonX,
		},

		TouchButton = {
			Position = UDim2.fromScale(0.81, 0.35),
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
			Gamepad = Enum.KeyCode.ButtonA,
		},

		TouchButton = {
			Position = UDim2.fromScale(0.8, 0.65),
			Scale = 1,
		},
	},

	Callback = function(name: string, value: ControlValue)
		(require)(callbacks.Keybind)(name, value)
	end,
})

table.insert(availableSettings, {
	Name = "Action 1",
	Tab = "Keybinds",
	Category = "Gameplay",
	Tooltip = "Activates action 1, if present.",
	Kind = "Control" :: "Control",
	SpecifyToggle = false,

	Default = {
		Toggled = true,
		Keybind = {
			KBMKeybind = Enum.KeyCode.N,
		},
	},

	Callback = function(name: string, value: ControlValue)
		(require)(callbacks.Keybind)(name, value)
	end,
})

table.insert(availableSettings, {
	Name = "Action 2",
	Tab = "Keybinds",
	Category = "Gameplay",
	Tooltip = "Activates action 2, if present.",
	Kind = "Control" :: "Control",
	SpecifyToggle = false,

	Default = {
		Toggled = true,
		Keybind = {
			KBMKeybind = Enum.KeyCode.M,
		},
	},

	Callback = function(name: string, value: ControlValue)
		(require)(callbacks.Keybind)(name, value)
	end,
})

table.insert(availableSettings, {
	Name = "Action 3",
	Tab = "Keybinds",
	Category = "Gameplay",
	Tooltip = "Activates action 3, if present.",
	Kind = "Control" :: "Control",
	SpecifyToggle = false,

	Default = {
		Toggled = true,
		Keybind = {
			KBMKeybind = Enum.KeyCode.Comma,
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
			Gamepad = Enum.KeyCode.ButtonB,
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
	Name = "Mouse Unlock",
	Tab = "Keybinds",
	Hidden = not isLocalAdmin,
	Category = "Menus",
	Kind = "Control" :: "Control",
	SpecifyToggle = false,
	Default = {
		Toggled = true,
		Keybind = {
			KBMKeybind = Enum.KeyCode.Quote,
		},
	},

	Callback = function(name: string, value: ControlValue)
		(require)(callbacks.Keybind)(name, value)
	end,
})

table.insert(availableSettings, {
	Name = "Inventory",
	Tab = "Keybinds",
	Category = "Menus",
	Kind = "Control" :: "Control",
	SpecifyToggle = false,
	Default = {
		Toggled = true,
		Keybind = {
			Gamepad = Enum.KeyCode.ButtonY,
		},
	},

	Callback = function(name: string, value: ControlValue)
		(require)(callbacks.Keybind)(name, value)
	end,
})

table.insert(availableSettings, {
	Name = "Menu Picker",
	Tab = "Keybinds",
	Category = "Menus",
	Kind = "Control" :: "Control",
	SpecifyToggle = false,
	Default = {
		Toggled = true,
		Keybind = {
			Gamepad = Enum.KeyCode.DPadUp,
		},
	},

	Callback = function(name: string, value: ControlValue)
		(require)(callbacks.Keybind)(name, value)
	end,
})

table.insert(availableSettings, {
	Name = "Sound Player",
	Tab = "Keybinds",
	Category = "Menus - Enable the checkbox to make a keybind toggled",
	Tooltip = "Opens the Sound Player menu.",
	Kind = "Control" :: "Control",
	SpecifyToggle = false,

	Default = {
		Toggled = true,
		Keybind = {
			KBMKeybind = Enum.KeyCode.K,
		}
	},

	Callback = function(name: string, value: ControlValue)
		(require)(callbacks.Keybind)(name, value)
	end,
})

table.insert(availableSettings, {
	Name = "Equipment",
	Tab = "Keybinds",
	Category = "Menus - Enable the checkbox to make a keybind toggled",
	Tooltip = "Opens the Equipment menu.",
	Kind = "Control" :: "Control",
	SpecifyToggle = true,

	Default = {
		Toggled = true,
		Keybind = {
			KBMKeybind = Enum.KeyCode.C,
			Gamepad = Enum.KeyCode.DPadLeft,
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
			Gamepad = Enum.KeyCode.DPadRight,
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

table.insert(availableSettings, {
	Name = "Next Item",
	Tab = "Keybinds",
	Category = "Inventory",
	Tooltip = "Cycles to the next item. Intended for use with gamepads.",
	Kind = "Control" :: "Control",
	SpecifyToggle = false,

	Default = {
		Toggled = true,
		Keybind = {
			Gamepad = Enum.KeyCode.ButtonR1,
		},
	},

	Callback = function(name: string, value: ControlValue)
		(require)(callbacks.Keybind)(name, value)
	end,
})

table.insert(availableSettings, {
	Name = "Previous Item",
	Tab = "Keybinds",
	Category = "Inventory",
	Tooltip = "Cycles to the previous item. Intended for use with gamepads.",
	Kind = "Control" :: "Control",
	SpecifyToggle = false,

	Default = {
		Toggled = true,
		Keybind = {
			Gamepad = Enum.KeyCode.ButtonL1,
		}
	},

	Callback = function(name: string, value: ControlValue)
		(require)(callbacks.Keybind)(name, value)
	end,
})

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

table.insert(availableSettings, {
	Name = "Team Voice",
	Tab = "Keybinds",
	Category = "Voice Chat",
	Kind = "Control" :: "Control",
	SpecifyToggle = false,

	Hidden = not isVcEnabled,

	Default = {
		Toggled = false,
		Keybind = {
			KBMKeybind = Enum.KeyCode.P,
			Gamepad = Enum.KeyCode.ButtonL3,
		},

		TouchButton = {
			Position = UDim2.fromScale(0.9, 0.65),
			Scale = 1,
		},
	},

	Callback = function(name: string, value: ControlValue)
		(require)(callbacks.Keybind)(name, value)
	end,
})

table.insert(availableSettings, {
	Name = "Chat",
	Tab = "Keybinds",
	Category = "Chat",
	Kind = "Control" :: "Control",
	SpecifyToggle = false,

	Default = {
		Toggled = true,
		Keybind = {
			KBMKeybind = Enum.KeyCode.Slash,
		},
	},

	Callback = function(name: string, value: ControlValue)
		(require)(callbacks.Keybind)(name, value)
	end
})

table.insert(availableSettings, {
	Name = "Team Chat",
	Tab = "Keybinds",
	Category = "Chat",
	Kind = "Control" :: "Control",
	SpecifyToggle = false,

	Default = {
		Toggled = true,
		Keybind = {
			KBMKeybind = Enum.KeyCode.T,
		},
	},

	Callback = function(name: string, value: ControlValue)
		(require)(callbacks.Keybind)(name, value)
	end,
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
			Gamepad = Enum.KeyCode.ButtonR3,
		},
	},

	Callback = function(name: string, value: ControlValue)
		(require)(callbacks.Keybind)(name, value)
	end,
})

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

table.insert(availableSettings, {
	Name = "Enable Sound Player Command",
	Tab = "Gameplay",
	Category = "Compatibility",
	Kind = "Boolean" :: "Boolean",

	Default = false,
})

return table.freeze(availableSettings)