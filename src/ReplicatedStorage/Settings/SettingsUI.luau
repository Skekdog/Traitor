local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UIAnimation = require(ReplicatedStorage.UIAnimation)
local UIManager = require(ReplicatedStorage.UIManager)
local SettingDefinitions = require(script.Parent.SettingDefinitions)
local Settings = require(script.Parent.Settings)
local module = {}

local ui = UIManager.WaitForUI("Settings") :: UIManager.UI & {Object: typeof(UIManager.UnregisteredUIs.Settings)}

local buttonTemplates = ui.Object.Templates

type BooleanButton = typeof(buttonTemplates.BooleanSetting)
type ChoiceButton = typeof(buttonTemplates.ChoiceSetting)
type KeybindButton = typeof(buttonTemplates.KeybindSetting)
type SelectButton = typeof(buttonTemplates.ButtonSetting)
type Button = BooleanButton | ChoiceButton | KeybindButton | SelectButton

local function setBooleanValue(button: BooleanButton, definition: SettingDefinitions.SettingDefinition, value: SettingDefinitions.BooleanValue)
	Settings.SetSetting(definition.Name, value)
	UIAnimation.TransitionSwitch(button.Value, value)
end

local function setupBooleanButton(definition: SettingDefinitions.SettingDefinition, value: SettingDefinitions.BooleanValue): BooleanButton
	local button = buttonTemplates.BooleanSetting:Clone()
	button.Label.Text = definition.Name .. ":"

	button.Activated:Connect(function()
		setBooleanValue(button, definition, not Settings.GetSetting(definition.Name))
	end)

	setBooleanValue(button, definition, value)

	return button
end

local function setupButton(definition: SettingDefinitions.SettingDefinition, value: SettingDefinitions.SettingValue)
	local button: GuiObject?
	if definition.Kind == "Boolean" then
		button = setupBooleanButton(definition, value :: SettingDefinitions.BooleanValue)
	elseif definition.Kind == "Choice" then
		-- button = setupChoiceButton(buttonTemplates.ChoiceSetting:Clone(), definition, value)
	elseif definition.Kind == "Keybind" then
		-- button = setupKeybindButton(buttonTemplates.KeybindSetting:Clone(), definition, value)
	elseif definition.Kind == "TouchPosition" then
		-- button = setupTouchPositionButton(buttonTemplates.ButtonSetting:Clone(), definition, value)
	end

	assert(button, "Unknown definition kind: " .. definition.Kind)

	button.Name = "Setting_" .. definition.Name
	button.Visible = true

	button.Parent = ui.Object.PageHolder.ScrollingFrame
end

function module.AddButton(definition: SettingDefinitions.SettingDefinition, value: SettingDefinitions.SettingValue): ()
	setupButton(definition, value)
end

return module