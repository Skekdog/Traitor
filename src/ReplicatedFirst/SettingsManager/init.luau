local HTTPService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local UserInputService = game:GetService("UserInputService")

local LocalRoundInfo: typeof(require(script.Parent.LocalRoundInfo))
local Types = require(script.Parent.RoundHandler.Types)

-- This module also gets called from the server. Might be better to move the JSONEncode and Decode to elsewhere (like say, the server because THATS THE ONLY ONE THAT USES THOSE!)
local UIScript, uiThemes
local UI: typeof(require(ReplicatedFirst.UIManager))
if game:GetService("RunService"):IsClient() then
	LocalRoundInfo = require(script.Parent.LocalRoundInfo)
	UIScript = ReplicatedFirst.UIManager
	UI = (require)(UIScript)
	
	uiThemes = {}
	for i, _ in UI.Themes do
		table.insert(uiThemes, i)
	end
end

export type SettingDefinition = {
	Name: string,
	Tab: "Display" | "Gameplay" | "Controls" | "Touch" | "General" | "Keybinds",
	Category: string,
	Tooltip: string,
	PossibleValues: {string} | "Boolean" | "Keybind" | "TouchPosition" | "TouchScale",
	Default: Setting,
	SpecifyToggle: boolean?, -- Whether the user can change if this is toggled or not. Only for keybinds.
	Callback: (val: Setting?, name: string?) -> nil,
}

export type Keybind = Enum.UserInputType | Enum.KeyCode
export type KeybindSetting = {
	["Keycodes"]: {{Keybind | nil}}, -- KeyCode + Modifier
	["Toggled"]: boolean,
}
export type Setting = KeybindSetting | string | boolean | UDim2 | number -- SelectionChoice, Boolean, TouchPosition, TouchScale

local module = {}

local function keybindCallback(val: any, name: any) -- annoying luau does not let me assert that val is a keybind
	local updated = script.SettingUpdated
	updated:Fire(name, val)
end

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
			local map = LocalRoundInfo.GetMap()
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
		PossibleValues = uiThemes :: {string},
		Default = "Dark",
		Callback = function(val) -- Can't directly reference UI.UpdateTheme because this module gets called from the server blah blah blah this sucks
			UI.UpdateTheme(val :: string)
		end,
	},
	{
		Name = "Close Scale",
		Tab = "Display",
		Category = "User Interface",
		Tooltip = "",
		PossibleValues = {"0", "0.25", "0.5", "0.75"},
		Default = "0.75",
		Callback = function() end,
	},
	{
		Name = "Close Speed",
		Tab = "Display",
		Category = "User Interface",
		Tooltip = "",
		PossibleValues = {"0.2", "0.3", "0.4", "0.5"},
		Default = "0.75",
		Callback = function() end,
	},
	{
		Name = "Animate UI Transitions",
		Tab = "Display",
		Category = "User Interface",
		Tooltip = "Enables animated transitions for all UI.",
		PossibleValues = "Boolean",
		Default = true,
		Callback = function() end,
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
			local sidebar = UI.WaitForUI("Sidebar")
			if sidebar then
				sidebar:ToggleVisible(val :: boolean)
			end
		end
	},
	{
		Name = "Background Menus",
		Tab = "Display",
		Category = "User Interface",
		Tooltip = "Hidden - Menus are not visible behind other menus, but are shown again when the menu is closed.\nClosed - Menus are closed when another is opened.\nStacked - Menus remain open when another is opened.",
		PossibleValues = {"Hidden", "Closed", "Stacked"},
		Default = "Hidden",
		Callback = function(val) UIScript:SetAttribute("BackgroundMenuMode", val) end,
	},
	
	{
		Name = "Snap to Ladders",
		Tab = "Gameplay",
		Category = "Controls",
		Tooltip = "Toggles automatic snapping to ladders. Ladders can still be manually used.",
		PossibleValues = "Boolean",
		Default = true,
		Callback = function() end,
	},
	
	{
		Name = "Primary Fire",
		Tab = "Keybinds",
		Category = "Items - Enable the checkbox to make a keybind toggled",
		Tooltip = "For using weapons or planting equipment.",
		PossibleValues = "Keybind",
		SpecifyToggle = false,
		Default = {Keycodes={{Enum.UserInputType.MouseButton1, nil :: any}}, Toggled=false},
		Callback = keybindCallback,
	},
	{
		Name = "Drop Ammo",
		Tab = "Keybinds",
		Category = "Items - Enable the checkbox to make a keybind toggled",
		Tooltip = "Empties the ammo of the currently equipped weapon into a box. Not all weapons can be emptied.",
		PossibleValues = "Keybind",
		SpecifyToggle = false,
		Default = {Keycodes={{Enum.KeyCode.Z, nil :: any}}, Toggled=true},
		Callback = keybindCallback,
	},
	{
		Name = "Reload Weapon",
		Tab = "Keybinds",
		Category = "Items - Enable the checkbox to make a keybind toggled",
		Tooltip = "Reloads the currently equipped weapon.",
		PossibleValues = "Keybind",
		SpecifyToggle = false,
		Default = {Keycodes={{Enum.KeyCode.R, nil :: any}, {Enum.KeyCode.ButtonX, nil :: any}}, Toggled=true},
		Callback = keybindCallback,
	},
	{
		Name = "Drop",
		Tab = "Keybinds",
		Category = "Items - Enable the checkbox to make a keybind toggled",
		Tooltip = "Drops the currently equipped item. Not all items can be dropped.",
		PossibleValues = "Keybind",
		SpecifyToggle = false,
		Default = {Keycodes={{Enum.KeyCode.Q, nil :: any}, {Enum.KeyCode.DPadDown}}, Toggled=true},
		Callback = keybindCallback,
	},
	{
		Name = "Alternate Fire",
		Tab = "Keybinds",
		Category = "Items - Enable the checkbox to make a keybind toggled",
		Tooltip = "For aiming weapons or using the alternate item function.",
		PossibleValues = "Keybind",
		SpecifyToggle = true,
		Default = {Keycodes={{Enum.UserInputType.MouseButton2, nil :: any}, {Enum.KeyCode.ButtonL2 :: any, nil :: any}}, Toggled=true},
		Callback = keybindCallback,
	},
	{
		Name = "Interact",
		Tab = "Keybinds",
		Category = "Gameplay",
		Tooltip = "General interaction",
		PossibleValues = "Keybind",
		SpecifyToggle = false,
		Default = {Keycodes={{Enum.KeyCode.F, nil :: any}, {Enum.KeyCode.ButtonA, nil :: any}}, Toggled=true},
		Callback = keybindCallback,
	},
	{
		Name = "Spectate Next",
		Tab = "Keybinds",
		Category = "Spectating - Enable the checkbox to make a keybind toggled",
		Tooltip = "Spectates the next player.",
		PossibleValues = "Keybind",
		SpecifyToggle = false,
		Default = {Keycodes={{Enum.KeyCode.E, nil :: any}, {Enum.KeyCode.DPadRight, nil :: any}}, Toggled=true},
		Callback = keybindCallback,
	},
	{
		Name = "Spectate Previous",
		Tab = "Keybinds",
		Category = "Spectating - Enable the checkbox to make a keybind toggled",
		Tooltip = "Spectates the previous player.",
		PossibleValues = "Keybind",
		SpecifyToggle = false,
		Default = {Keycodes={{Enum.KeyCode.Q, nil :: any}, {Enum.KeyCode.DPadLeft, nil :: any}}, Toggled=true},
		Callback = keybindCallback,
	},
	--{
	--	Name = "Crouch",
	--	Tab = "Keybinds",
	--	Category = "Movement - Enable the checkbox to make a keybind toggled",
	--	Tooltip = "Not functional.",
	--	PossibleValues = "Keybind",
	--  SpecifyToggle = true,
	--	Default = {Keycodes={{Enum.KeyCode.LeftControl, nil}}, Toggled=false},
	--	Callback = keybindCallback,
	--},
	{
		Name = "Close UI",
		Tab = "Keybinds",
		Category = "Menus - Enable the checkbox to make a keybind toggled",
		Tooltip = "Closes the fore-most UI.",
		PossibleValues = "Keybind",
		SpecifyToggle = false,
		Default = {Keycodes={{Enum.KeyCode.X, nil :: any}, {Enum.KeyCode.ButtonB, nil :: any}}, Toggled=true},
		Callback = keybindCallback,
	},
	
	{
		Name = "Next Weapon",
		Tab = "Keybinds",
		Category = "Inventory - Enable the checkbox to make a keybind toggled",
		Tooltip = "Cycles to the next weapon. Primarily used for controllers.",
		PossibleValues = "Keybind",
		SpecifyToggle = false,
		Default = {Keycodes={{Enum.KeyCode.ButtonY, nil :: any}}, Toggled=true},
		Callback = keybindCallback,
	},
	{
		Name = "Slot 1",
		Tab = "Keybinds",
		Category = "Inventory - Enable the checkbox to make a keybind toggled",
		Tooltip = "Equips the item in slot 1.",
		PossibleValues = "Keybind",
		SpecifyToggle = false,
		Default = {Keycodes={{Enum.KeyCode.One, nil :: any}}, Toggled=true},
		Callback = keybindCallback,
	},
	{
		Name = "Slot 2",
		Tab = "Keybinds",
		Category = "Inventory - Enable the checkbox to make a keybind toggled",
		Tooltip = "Equips the item in slot 2.",
		PossibleValues = "Keybind",
		SpecifyToggle = false,
		Default = {Keycodes={{Enum.KeyCode.Two, nil :: any}}, Toggled=true},
		Callback = keybindCallback,
	},
	{
		Name = "Slot 3",
		Tab = "Keybinds",
		Category = "Inventory - Enable the checkbox to make a keybind toggled",
		Tooltip = "Equips the item in slot 3.",
		PossibleValues = "Keybind",
		SpecifyToggle = false,
		Default = {Keycodes={{Enum.KeyCode.Three, nil :: any}}, Toggled=true},
		Callback = keybindCallback,
	},
	{
		Name = "Slot 4",
		Tab = "Keybinds",
		Category = "Inventory - Enable the checkbox to make a keybind toggled",
		Tooltip = "Equips the item in slot 4.",
		PossibleValues = "Keybind",
		SpecifyToggle = false,
		Default = {Keycodes={{Enum.KeyCode.Four, nil :: any}}, Toggled=true},
		Callback = keybindCallback,
	},
	{
		Name = "Slot 5",
		Tab = "Keybinds",
		Category = "Inventory - Enable the checkbox to make a keybind toggled",
		Tooltip = "Equips the item in slot 5.",
		PossibleValues = "Keybind",
		SpecifyToggle = false,
		Default = {Keycodes={{Enum.KeyCode.Five, nil :: any}}, Toggled=true},
		Callback = keybindCallback,
	},
	{
		Name = "Slot 6",
		Tab = "Keybinds",
		Category = "Inventory - Enable the checkbox to make a keybind toggled",
		Tooltip = "Equips the item in slot 6.",
		PossibleValues = "Keybind",
		SpecifyToggle = false,
		Default = {Keycodes={{Enum.KeyCode.Six, nil :: any}}, Toggled=true},
		Callback = keybindCallback,
	},
	{
		Name = "Slot 7",
		Tab = "Keybinds",
		Category = "Inventory - Enable the checkbox to make a keybind toggled",
		Tooltip = "Equips the item in slot 7.",
		PossibleValues = "Keybind",
		SpecifyToggle = false,
		Default = {Keycodes={{Enum.KeyCode.Seven, nil :: any}}, Toggled=true},
		Callback = keybindCallback,
	},
	{
		Name = "Slot 8",
		Tab = "Keybinds",
		Category = "Inventory - Enable the checkbox to make a keybind toggled",
		Tooltip = "Equips the item in slot 8.",
		PossibleValues = "Keybind",
		SpecifyToggle = false,
		Default = {Keycodes={{Enum.KeyCode.Eight, nil :: any}}, Toggled=true},
		Callback = keybindCallback,
	},
	{
		Name = "Slot 9",
		Tab = "Keybinds",
		Category = "Inventory - Enable the checkbox to make a keybind toggled",
		Tooltip = "Equips the item in slot 9.",
		PossibleValues = "Keybind",
		SpecifyToggle = false,
		Default = {Keycodes={{Enum.KeyCode.Nine, nil :: any}}, Toggled=true},
		Callback = keybindCallback,
	},
	
	{
		Name = "Equipment Shop",
		Tab = "Keybinds",
		Category = "Menus - Enable the checkbox to make a keybind toggled",
		Tooltip = "Opens the equipment shop. Only available for certain roles.",
		PossibleValues = "Keybind",
		SpecifyToggle = true,
		Default = {Keycodes={{Enum.KeyCode.C, nil :: any}, {Enum.KeyCode.DPadUp, nil :: any}}, Toggled=true},
		Callback = keybindCallback,
	},
	{
		Name = "Playerlist",
		Tab = "Keybinds",
		Category = "Menus - Enable the checkbox to make a keybind toggled",
		Tooltip = "Opens the playerlist.",
		PossibleValues = "Keybind",
		SpecifyToggle = true,
		Default = {Keycodes={{Enum.KeyCode.Tab, nil :: any}, {Enum.KeyCode.ButtonL3, nil :: any}}, Toggled=false},
		Callback = keybindCallback,
	},
	{
		Name = "Settings",
		Tab = "Keybinds",
		Category = "Menus - Enable the checkbox to make a keybind toggled",
		Tooltip = "Opens the settings page. Can also be opened by typing !settings in chat.",
		PossibleValues = "Keybind",
		SpecifyToggle = true,
		Default = {Keycodes={{Enum.KeyCode.G, nil :: any}, {Enum.KeyCode.ButtonR3, nil :: any}}, Toggled=true},
		Callback = keybindCallback,
	},
	{
		Name = "Highlights",
		Tab = "Keybinds",
		Category = "Menus - Enable the checkbox to make a keybind toggled",
		Tooltip = "Opens the round highlights.",
		PossibleValues = "Keybind",
		SpecifyToggle = true,
		Default = {Keycodes={{Enum.KeyCode.B, nil :: any}}, Toggled=true},
		Callback = keybindCallback,
	},
	
	
	{
		Name = "Primary Fire Position",
		Tab = "Touch",
		Category = "Button Positions",
		Tooltip = "Primary fire is used to shoot a weapon or plant equipment.",
		PossibleValues = "TouchPosition",
		Default = UDim2.fromScale(0.1, 0.1),
		Callback = keybindCallback,
	},
	{
		Name = "Reload Weapon Position",
		Tab = "Touch",
		Category = "Button Positions",
		Tooltip = "Reloads the currently equipped weapon.",
		PossibleValues = "TouchPosition",
		Default = UDim2.fromScale(0.1, 0.2),
		Callback = keybindCallback,
	},
	{
		Name = "Drop Position",
		Tab = "Touch",
		Category = "Button Positions",
		Tooltip = "Drops the currently equipped item. Not all items can be dropped.",
		PossibleValues = "TouchPosition",
		Default = UDim2.fromScale(0.1, 0.3),
		Callback = keybindCallback,
	},
	{
		Name = "Alternate Fire Position",
		Tab = "Touch",
		Category = "Button Positions",
		Tooltip = "Alternate fire is used to aim a weapon or use the alternate function of equipment.",
		PossibleValues = "TouchPosition",
		Default = UDim2.fromScale(0.1, 0.4),
		Callback = keybindCallback,
	},
	{
		Name = "Interact Position",
		Tab = "Touch",
		Category = "Button Positions",
		Tooltip = "Used for general interaction, such as climbing ladders or using Health Stations.",
		PossibleValues = "TouchPosition",
		Default = UDim2.fromScale(0.1, 0.5),
		Callback = keybindCallback,
	},
	{
		Name = "Drop Ammo Position",
		Tab = "Touch",
		Category = "Button Positions",
		Tooltip = "Empties the ammo of the currently equipped weapon into a box. Not all weapons can be emptied.",
		PossibleValues = "TouchPosition",
		Default = UDim2.fromScale(0.1, 0.6),
		Callback = keybindCallback,
	},
	
	{
		Name = "Primary Fire Scale",
		Tab = "Touch",
		Category = "Button Scale",
		Tooltip = "Primary fire is used to shoot a weapon or plant equipment.",
		PossibleValues = "TouchScale",
		Default = 1,
		Callback = keybindCallback,
	},
	{
		Name = "Reload Weapon Scale",
		Tab = "Touch",
		Category = "Button Scale",
		Tooltip = "Reloads the currently equipped weapon.",
		PossibleValues = "TouchScale",
		Default = 1,
		Callback = keybindCallback,
	},
	{
		Name = "Drop Scale",
		Tab = "Touch",
		Category = "Button Scale",
		Tooltip = "Drops the currently equipped item. Not all items can be dropped.",
		PossibleValues = "TouchScale",
		Default = 1,
		Callback = keybindCallback,
	},
	{
		Name = "Alternate Fire Scale",
		Tab = "Touch",
		Category = "Button Scale",
		Tooltip = "Alternate fire is used to aim a weapon or use the alternate function of equipment.",
		PossibleValues = "TouchScale",
		Default = 1,
		Callback = keybindCallback,
	},
	{
		Name = "Interact Scale",
		Tab = "Touch",
		Category = "Button Scale",
		Tooltip = "Used for general interaction, such as climbing ladders or using Health Stations.",
		PossibleValues = "TouchScale",
		Default = 1,
		Callback = keybindCallback,
	},
	{
		Name = "Drop Ammo Scale",
		Tab = "Touch",
		Category = "Button Scale",
		Tooltip = "Empties the ammo of the currently equipped weapon into a box. Not all weapons can be emptied.",
		PossibleValues = "TouchScale",
		Default = 1,
		Callback = keybindCallback
	}
} :: {SettingDefinition}


for _, v in module.AvailableSettings do
	module.Settings[v.Name] = {Value = v.Default, Definition = v}
end

function module.SetSetting(setting: string, settingValue: Setting)
	module.Settings[setting].Value = settingValue
	module.Settings[setting].Definition.Callback(settingValue, setting)
end

function module.GetSetting(settingName: string): Setting
	return module.Settings[settingName].Value
end

-- This whole section of serialisation is horrid but it works
local function keybindToJson(keybind: KeybindSetting): string
	local keycodeText = '['
	for i, v in keybind.Keycodes do
		keycodeText = `{keycodeText}["{v[1]}{v[2] and `","{v[2]}"` or `"`}]`
		if i < #keybind.Keycodes then
			keycodeText = keycodeText..","
		end
	end
	keycodeText = keycodeText..']'
	return `\{"Keycodes":{keycodeText},"Toggled":{keybind.Toggled}}`
end

function module.JSONEncode(): string
	local toEncode = {}
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

function module.JSONDecode(optionsString): {}
	local options = HTTPService:JSONDecode(optionsString)
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
			local result = HTTPService:JSONDecode(v)
			for b, keybindList in result.Keycodes do
				for a, keybind in keybindList do
					result.Keycodes[b][a] = (Enum :: any)[keybind:split(".")[2]][keybind:split(".")[3]]
				end
			end
			options[i] = result
		elseif isTouchPosition then
			options[i] = UDim2.new(v[1], v[2], v[3], v[4])
		end
	end
	return options
end

return module
