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

local function setBooleanValue(button: BooleanButton, definition: SettingDefinitions.BooleanDefinition, value: SettingDefinitions.BooleanValue)
	Settings.SetSetting(definition.Name, value)
	UIAnimation.TransitionSwitch(button.Value, value)
end

local function setupBooleanButton(definition: SettingDefinitions.BooleanDefinition, value: SettingDefinitions.BooleanValue): BooleanButton
	local button = buttonTemplates.BooleanSetting:Clone()
	button.Label.Text = definition.Name .. ":"

	button.Activated:Connect(function()
		setBooleanValue(button, definition, not Settings.GetSetting(definition.Name))
	end)

	setBooleanValue(button, definition, value)

	return button
end

local function setChoiceValue(button: ChoiceButton, choiceButton: TextButton, definition: SettingDefinitions.ChoiceDefinition, value: SettingDefinitions.ChoiceValue): ()
	Settings.SetSetting(definition.Name, value)
	UIAnimation.TransitionUnderline(button.Choices.Underline, choiceButton)
end

local function setupChoiceButton(definition: SettingDefinitions.ChoiceDefinition, value: SettingDefinitions.ChoiceValue): ChoiceButton
	local button = buttonTemplates.ChoiceSetting:Clone()
	button.Label.Text = definition.Name .. ":"

	local choiceButton = button.Choices.Choice

	for i, choice in definition.PossibleValues do
		local but = choiceButton:Clone()
		but.Text = choice
		but.Visible = true

		but.Name = "Choice_" .. choice

		but.Position = UDim2.fromScale((i - 1) / #definition.PossibleValues + 0.1, 0.5)

		but.Activated:Connect(function()
			setChoiceValue(button, but, definition, value)
		end)

		but.Parent = button.Choices

		if value == choice then
			task.defer(setChoiceValue, button, but, definition, value)
		end
	end

	return button
end

local function setupButton(definition: SettingDefinitions.SettingDefinition, value: SettingDefinitions.SettingValue)
	local button: GuiObject?
	if definition.Kind == "Boolean" then
		button = setupBooleanButton(definition, value :: SettingDefinitions.BooleanValue)
	elseif definition.Kind == "Choice" then
		button = setupChoiceButton(definition, value :: SettingDefinitions.ChoiceValue)
	elseif definition.Kind == "Keybind" then
		-- button = setupKeybindButton(definition, value)
	elseif definition.Kind == "TouchPosition" then
		-- button = setupTouchPositionButton(definition, value)
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