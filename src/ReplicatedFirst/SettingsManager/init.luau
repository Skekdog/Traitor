local HTTPService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local UserInputService = game:GetService("UserInputService")

local Types = require(script.Parent.RoundHandler.Types)

export type SettingDefinition = {
	Name: string,
	Tab: "Display" | "Gameplay" | "Controls" | "Touch" | "General" | "Keybinds",
	Category: string,
	Tooltip: string,
	PossibleValues: {string} | "Boolean" | "Keybind" | "TouchPosition" | "TouchScale",
	Default: Setting,
	SpecifyToggle: boolean?, -- Whether the user can change if this is toggled or not. Only for keybinds.
	Callback: ((val: Setting?, name: string?) -> ())?,
}

export type Keybind = Enum.UserInputType | Enum.KeyCode
export type KeybindSetting = {
	Keycodes: {Keybind},
	Toggled: boolean,
}
export type Setting = KeybindSetting | string | boolean | UDim2 | number -- SelectionChoice, Boolean, TouchPosition, TouchScale

local module = {}

module.SETTINGS_VERSION = 3
module.Settings = {}
module.AvailableSettings = {
	{
		Name = "Shadows",
		Tab = "Display",
		Category = "Environment",
		Tooltip = "Enable or disable global shadows.",
		PossibleValues = "Boolean",
		Default = true,
		Callback = function(val)
			game:GetService("Lighting").GlobalShadows = val :: boolean
		end,
	},
	{
		Name = "Use FIB Lighting",
		Tab = "Display",
		Category = "Environment",
		Tooltip = "If you have modified your client to use Future lighting, enable this for better map compatibility.",
		PossibleValues = "Boolean",
		Default = false,
		Callback = function(val)
			local map = require(script.Parent.LocalRoundInfo).GetMap()
			if not map then
				return
			end

			local mapConfig: Types.LightingStructure?
			if val then
				mapConfig = map.Map:FindFirstChild("FIBLighting") :: Types.LightingStructure?
			else
				mapConfig = map:FindFirstChild("Lighting") :: Types.LightingStructure?
			end
			if mapConfig then
				for _, prop in mapConfig:GetChildren() do
					if prop:IsA("ValueBase") then
						(Lighting :: any)[prop.Name] = (prop :: any).Value
					end
				end
			end
		end,
	},

	{
		Name = "Keep Shattered Glass",
		Tab = "Display",
		Category = "Environment",
		Tooltip = "Prevents shattered glass from despawning until the round is over.",
		PossibleValues = "Boolean",
		Default = false,
		Callback = function(val)
			if val then
				return
			end

			for _, v in workspace.Projectiles:GetChildren() do
				if v.Name == "GlassFragment" then
					v:Destroy()
				end
			end
		end
	},
	
	{
		Name = "UI Theme",
		Tab = "Display",
		Category = "User Interface",
		Tooltip = "Select a theme for the UI.",
		PossibleValues = {"Dark", "Light", "Blue"},
		Default = "Dark",
		Callback = function(val) -- Can't directly reference this because cyclic dependency!
			require(script.Parent.ThemesManager).UpdateTheme(val)
		end,
	},
	{
		Name = "Sidebar Alignment",
		Tab = "Display",
		Category = "User Interface",
		Tooltip = "Controls the position of the sidebar. May be useful on phones with inset screens.",
		PossibleValues = {"Left", "Right"},
		Default = "Right",
		Callback = function(val)
			require(script.Parent.UIManager.UIScripts.SetSidebarAlignment)(val)
		end
	},
	{
		Name = "Animate UI Transitions",
		Tab = "Display",
		Category = "User Interface",
		Tooltip = "Enables animated transitions for all UI.",
		PossibleValues = "Boolean",
		Default = true,
	},
	{
		Name = "Show Item Hints",
		Tab = "Display",
		Category = "User Interface",
		Tooltip = "Enables hint text for item controls.",
		PossibleValues = "Boolean",
		Default = true,
		Callback = function(val)
			if not ReplicatedFirst:GetAttribute("ControlsReady") then -- not a good fix, desperately need a better system for all this settings and ui interop
				return
			end
			if not val then
				require(script.Parent.ItemHint)()
			end
		end,
	},
	{
		Name = "Always Show Sidebar",
		Tab = "Display",
		Category = "User Interface",
		Tooltip = "This setting has no effect if a keyboard is not connected.",
		PossibleValues = "Boolean",
		Default = true,
		Callback = function(val)
			if not UserInputService.KeyboardEnabled then
				return
			end
			local sidebar = require(script.Parent.UIManager).WaitForUI("Sidebar")
			if sidebar then
				sidebar:ToggleVisible(val :: boolean)
			end
		end
	},
	{
		Name = "Background Menus",
		Tab = "Display",
		Category = "User Interface",
		Tooltip = "Closed - Menus are closed when another is opened.\nStacked - Menus remain open when another is opened.",
		PossibleValues = {"Closed", "Stacked"},
		Default = "Closed",
		Callback = function(val)
			script.Parent.UIManager:SetAttribute("BackgroundMenuMode", val)
		end,
	},
	{
		Name = "Close Scale",
		Tab = "Display",
		Category = "Development",
		Tooltip = "Intended for dev use only.",
		PossibleValues = {"0", "0.25", "0.5", "0.75"},
		Default = "0.75",
	},
	{
		Name = "Close Speed",
		Tab = "Display",
		Category = "Development",
		Tooltip = "Intended for dev use only.",
		PossibleValues = {"0.2", "0.3", "0.4", "0.5"},
		Default = "0.2",
	},
	
	{
		Name = "Snap to Ladders",
		Tab = "Gameplay",
		Category = "Controls",
		Tooltip = "Toggles automatic snapping to ladders. Ladders can still be manually used.",
		PossibleValues = "Boolean",
		Default = true,
	},
	{
		Name = "Toggle Aim",
		Tab = "Gameplay",
		Category = "Controls",
		Tooltip = "Determines whether the Alternate Fire key should be toggled to aim.",
		PossibleValues = "Boolean",
		Default = false,
	},
	
	{
		Name = "Primary Fire",
		Tab = "Keybinds",
		Category = "Items",
		Tooltip = "For using weapons or planting equipment.",
		PossibleValues = "Keybind",
		SpecifyToggle = false,
		Default = {Keycodes = {Enum.UserInputType.MouseButton1}, Toggled = false},
	},
	{
		Name = "Drop Ammo",
		Tab = "Keybinds",
		Category = "Items",
		Tooltip = "Empties the ammo of the currently equipped weapon into a box. Not all weapons can be emptied.",
		PossibleValues = "Keybind",
		SpecifyToggle = false,
		Default = {Keycodes = {Enum.KeyCode.Z}, Toggled = true},
	},
	{
		Name = "Reload Weapon",
		Tab = "Keybinds",
		Category = "Items",
		Tooltip = "Reloads the currently equipped weapon.",
		PossibleValues = "Keybind",
		SpecifyToggle = false,
		Default = {Keycodes = {Enum.KeyCode.R, Enum.KeyCode.ButtonX}, Toggled = true},
	},
	{
		Name = "Drop",
		Tab = "Keybinds",
		Category = "Items",
		Tooltip = "Drops the currently equipped item. Not all items can be dropped.",
		PossibleValues = "Keybind",
		SpecifyToggle = false,
		Default = {Keycodes = {Enum.KeyCode.Q, Enum.KeyCode.DPadDown}, Toggled = true},
	},
	{
		Name = "Alternate Fire",
		Tab = "Keybinds",
		Category = "Items",
		Tooltip = "For aiming weapons or using the alternate item function.",
		PossibleValues = "Keybind",
		SpecifyToggle = false,
		Default = {Keycodes = {Enum.UserInputType.MouseButton2, Enum.KeyCode.ButtonL2}, Toggled = false},
	},
	{
		Name = "Interact",
		Tab = "Keybinds",
		Category = "Gameplay",
		Tooltip = "General interaction",
		PossibleValues = "Keybind",
		SpecifyToggle = false,
		Default = {Keycodes = {Enum.KeyCode.F, Enum.KeyCode.ButtonA}, Toggled = true},
	},
	{
		Name = "Climb Ladder",
		Tab = "Keybinds",
		Category = "Gameplay",
		Tooltip = "Begins or ends climbing a ladder.",
		PossibleValues = "Keybind",
		SpecifyToggle = false,
		Default = {Keycodes = {Enum.KeyCode.E}, Toggled = true},
	},
	{
		Name = "Spectate Next",
		Tab = "Keybinds",
		Category = "Spectating",
		Tooltip = "Spectates the next player.",
		PossibleValues = "Keybind",
		SpecifyToggle = false,
		Default = {Keycodes = {Enum.KeyCode.E, Enum.KeyCode.DPadRight}, Toggled = true},
	},
	{
		Name = "Spectate Previous",
		Tab = "Keybinds",
		Category = "Spectating",
		Tooltip = "Spectates the previous player.",
		PossibleValues = "Keybind",
		SpecifyToggle = false,
		Default = {Keycodes = {Enum.KeyCode.Q, Enum.KeyCode.DPadLeft}, Toggled = true},
	},
	--{
	--	Name = "Crouch",
	--	Tab = "Keybinds",
	--	Category = "Movement",
	--	Tooltip = "Not functional.",
	--	PossibleValues = "Keybind",
	--  SpecifyToggle = true,
	--	Default = {Keycodes={{Enum.KeyCode.LeftControl, nil}}, Toggled=false},
	--	Callback = keybindCallback,
	--},
	{
		Name = "Close UI",
		Tab = "Keybinds",
		Category = "Menus",
		Tooltip = "Closes the fore-most UI.",
		PossibleValues = "Keybind",
		SpecifyToggle = false,
		Default = {Keycodes = {Enum.KeyCode.X, Enum.KeyCode.ButtonB}, Toggled = true},
	},

	{
		Name = "Next Weapon",
		Tab = "Keybinds",
		Category = "Inventory",
		Tooltip = "Cycles to the next weapon. Primarily used for controllers.",
		PossibleValues = "Keybind",
		SpecifyToggle = false,
		Default = {Keycodes = {Enum.KeyCode.ButtonY}, Toggled = true},
	},
	{
		Name = "Slot 1",
		Tab = "Keybinds",
		Category = "Inventory",
		Tooltip = "Equips the item in slot 1.",
		PossibleValues = "Keybind",
		SpecifyToggle = false,
		Default = {Keycodes = {Enum.KeyCode.One}, Toggled = true},
	},
	{
		Name = "Slot 2",
		Tab = "Keybinds",
		Category = "Inventory",
		Tooltip = "Equips the item in slot 2.",
		PossibleValues = "Keybind",
		SpecifyToggle = false,
		Default = {Keycodes={Enum.KeyCode.Two}, Toggled = true},
	},
	{
		Name = "Slot 3",
		Tab = "Keybinds",
		Category = "Inventory",
		Tooltip = "Equips the item in slot 3.",
		PossibleValues = "Keybind",
		SpecifyToggle = false,
		Default = {Keycodes = {Enum.KeyCode.Three}, Toggled = true},
	},
	{
		Name = "Slot 4",
		Tab = "Keybinds",
		Category = "Inventory",
		Tooltip = "Equips the item in slot 4.",
		PossibleValues = "Keybind",
		SpecifyToggle = false,
		Default = {Keycodes = {Enum.KeyCode.Four}, Toggled = true},
	},
	{
		Name = "Slot 5",
		Tab = "Keybinds",
		Category = "Inventory",
		Tooltip = "Equips the item in slot 5.",
		PossibleValues = "Keybind",
		SpecifyToggle = false,
		Default = {Keycodes = {Enum.KeyCode.Five}, Toggled = true},
	},
	{
		Name = "Slot 6",
		Tab = "Keybinds",
		Category = "Inventory",
		Tooltip = "Equips the item in slot 6.",
		PossibleValues = "Keybind",
		SpecifyToggle = false,
		Default = {Keycodes = {Enum.KeyCode.Six}, Toggled = true},
	},
	{
		Name = "Slot 7",
		Tab = "Keybinds",
		Category = "Inventory",
		Tooltip = "Equips the item in slot 7.",
		PossibleValues = "Keybind",
		SpecifyToggle = false,
		Default = {Keycodes = {Enum.KeyCode.Seven}, Toggled = true},
	},
	{
		Name = "Slot 8",
		Tab = "Keybinds",
		Category = "Inventory",
		Tooltip = "Equips the item in slot 8.",
		PossibleValues = "Keybind",
		SpecifyToggle = false,
		Default = {Keycodes = {Enum.KeyCode.Eight}, Toggled = true},
	},
	{
		Name = "Slot 9",
		Tab = "Keybinds",
		Category = "Inventory",
		Tooltip = "Equips the item in slot 9.",
		PossibleValues = "Keybind",
		SpecifyToggle = false,
		Default = {Keycodes = {Enum.KeyCode.Nine}, Toggled = true},
	},
	
	{
		Name = "Equipment Shop",
		Tab = "Keybinds",
		Category = "Menus - Enable the checkbox to make a keybind toggled",
		Tooltip = "Opens the equipment shop. Only available for certain roles.",
		PossibleValues = "Keybind",
		SpecifyToggle = true,
		Default = {Keycodes = {Enum.KeyCode.C, Enum.KeyCode.DPadUp}, Toggled = true},
	},
	{
		Name = "Playerlist",
		Tab = "Keybinds",
		Category = "Menus - Enable the checkbox to make a keybind toggled",
		Tooltip = "Opens the playerlist.",
		PossibleValues = "Keybind",
		SpecifyToggle = true,
		Default = {Keycodes = {Enum.KeyCode.Tab, Enum.KeyCode.ButtonL3}, Toggled = false},
	},
	{
		Name = "Settings",
		Tab = "Keybinds",
		Category = "Menus - Enable the checkbox to make a keybind toggled",
		Tooltip = "Opens the settings page. Can also be opened by typing !settings in chat.",
		PossibleValues = "Keybind",
		SpecifyToggle = true,
		Default = {Keycodes = {Enum.KeyCode.G, Enum.KeyCode.ButtonR3}, Toggled = true},
	},
	{
		Name = "Highlights",
		Tab = "Keybinds",
		Category = "Menus - Enable the checkbox to make a keybind toggled",
		Tooltip = "Opens the round highlights.",
		PossibleValues = "Keybind",
		SpecifyToggle = true,
		Default = {Keycodes = {Enum.KeyCode.B}, Toggled = true},
	},
	
	
	{
		Name = "Primary Fire Position",
		Tab = "Touch",
		Category = "Button Positions",
		Tooltip = "Primary fire is used to shoot a weapon or plant equipment.",
		PossibleValues = "TouchPosition",
		Default = UDim2.fromScale(0.1, 0.1),
	},
	{
		Name = "Reload Weapon Position",
		Tab = "Touch",
		Category = "Button Positions",
		Tooltip = "Reloads the currently equipped weapon.",
		PossibleValues = "TouchPosition",
		Default = UDim2.fromScale(0.1, 0.2),
	},
	{
		Name = "Drop Position",
		Tab = "Touch",
		Category = "Button Positions",
		Tooltip = "Drops the currently equipped item. Not all items can be dropped.",
		PossibleValues = "TouchPosition",
		Default = UDim2.fromScale(0.1, 0.3),
	},
	{
		Name = "Alternate Fire Position",
		Tab = "Touch",
		Category = "Button Positions",
		Tooltip = "Alternate fire is used to aim a weapon or use the alternate function of equipment.",
		PossibleValues = "TouchPosition",
		Default = UDim2.fromScale(0.1, 0.4),
	},
	{
		Name = "Interact Position",
		Tab = "Touch",
		Category = "Button Positions",
		Tooltip = "Used for general interaction, such as climbing ladders or using Health Stations.",
		PossibleValues = "TouchPosition",
		Default = UDim2.fromScale(0.1, 0.5),
	},
	{
		Name = "Drop Ammo Position",
		Tab = "Touch",
		Category = "Button Positions",
		Tooltip = "Empties the ammo of the currently equipped weapon into a box. Not all weapons can be emptied.",
		PossibleValues = "TouchPosition",
		Default = UDim2.fromScale(0.1, 0.6),
	},
	{
		Name = "Climb Ladder Position",
		Tab = "Touch",
		Category = "Button Positions",
		Tooltip = "Empties the ammo of the currently equipped weapon into a box. Not all weapons can be emptied.",
		PossibleValues = "TouchPosition",
		Default = UDim2.fromScale(0.1, 0.7),
	},
	
	{
		Name = "Primary Fire Scale",
		Tab = "Touch",
		Category = "Button Scale",
		Tooltip = "Primary fire is used to shoot a weapon or plant equipment.",
		PossibleValues = "TouchScale",
		Default = 1,
	},
	{
		Name = "Reload Weapon Scale",
		Tab = "Touch",
		Category = "Button Scale",
		Tooltip = "Reloads the currently equipped weapon.",
		PossibleValues = "TouchScale",
		Default = 1,
	},
	{
		Name = "Drop Scale",
		Tab = "Touch",
		Category = "Button Scale",
		Tooltip = "Drops the currently equipped item. Not all items can be dropped.",
		PossibleValues = "TouchScale",
		Default = 1,
	},
	{
		Name = "Alternate Fire Scale",
		Tab = "Touch",
		Category = "Button Scale",
		Tooltip = "Alternate fire is used to aim a weapon or use the alternate function of equipment.",
		PossibleValues = "TouchScale",
		Default = 1,
	},
	{
		Name = "Interact Scale",
		Tab = "Touch",
		Category = "Button Scale",
		Tooltip = "Used for general interaction, such as climbing ladders or using Health Stations.",
		PossibleValues = "TouchScale",
		Default = 1,
	},
	{
		Name = "Drop Ammo Scale",
		Tab = "Touch",
		Category = "Button Scale",
		Tooltip = "Empties the ammo of the currently equipped weapon into a box. Not all weapons can be emptied.",
		PossibleValues = "TouchScale",
		Default = 1,
	},
	{
		Name = "Climb Ladder Scale",
		Tab = "Touch",
		Category = "Button Scale",
		Tooltip = "Empties the ammo of the currently equipped weapon into a box. Not all weapons can be emptied.",
		PossibleValues = "TouchScale",
		Default = 1,
	},
} :: {SettingDefinition}


for _, v in module.AvailableSettings do
	module.Settings[v.Name] = {Value = v.Default, Definition = v}
end

function module.SetSetting(setting: string, settingValue: Setting)
	local ref = module.Settings[setting]
	ref.Value = settingValue
	if ref.Definition.Callback then
		ref.Definition.Callback(settingValue, setting)
	end
end

function module.GetSetting(settingName: string): Setting
	return module.Settings[settingName].Value
end

-- This whole section of serialisation is horrid but it works
local function keybindToJson(keybind: KeybindSetting): string
	local keycodeText = '['
	for i, v in keybind.Keycodes do
		keycodeText = keycodeText .. `"{v}"` .. if i < #keybind.Keycodes then "," else ""
	end
	keycodeText = keycodeText..']'
	return `\{"Keycodes":{keycodeText},"Toggled":{keybind.Toggled}}`
end

function module.JSONEncode(): string
	local toEncode = {__VERSION = module.SETTINGS_VERSION}
	for i, v in module.Settings do
		local value = v.Value
		local converted: any = value
		if typeof(value) == "UDim2" then
			converted = {value.X.Scale, value.X.Offset, value.Y.Scale, value.Y.Offset}
		elseif (typeof(value) == "table") and value.Keycodes then
			converted = keybindToJson(value)
		end
		toEncode[i] = converted
	end
	return HTTPService:JSONEncode(toEncode)
end

function module.JSONDecode(optionsString): {} | false
	local options = HTTPService:JSONDecode(optionsString)
	local version = options.__VERSION
	if version ~= module.SETTINGS_VERSION then
		return false
	end
	for i, v in options do
		local isKeybind, isTouchPosition
		for _, p in module.AvailableSettings do
			if p.Name == i then
				isKeybind = p.PossibleValues == "Keybind"
				isTouchPosition = p.PossibleValues == "TouchPosition"
				break
			end
		end
		if isKeybind then
			local result = HTTPService:JSONDecode(v) :: KeybindSetting
			for b, keybind in result.Keycodes do
				assert(typeof(keybind) == "string")
				result.Keycodes[b] = (Enum :: any)[keybind:split(".")[2]][keybind:split(".")[3]]
			end
			options[i] = result
		elseif isTouchPosition then
			options[i] = UDim2.new(v[1], v[2], v[3], v[4])
		end
	end
	return options
end

return module
