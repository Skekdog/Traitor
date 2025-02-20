local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ControlManager = require(ReplicatedStorage.ControlManager)
local ScreenMessage = require(ReplicatedStorage.ScreenMessage)
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
type ClickButton = typeof(buttonTemplates.ClickButton)
type Button = BooleanButton | ChoiceButton | KeybindButton | ClickButton

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

local function listenForInput(kbm: boolean): Enum.UserInputType | Enum.KeyCode?
	local inputTypes: {Enum.UserInputType}
	if kbm then
		inputTypes = {
			Enum.UserInputType.MouseButton1,
			Enum.UserInputType.MouseButton2,
			Enum.UserInputType.MouseButton3,
			Enum.UserInputType.Keyboard,
		}
	else
		inputTypes = {
			Enum.UserInputType.Gamepad1,
		}
	end

	local result: Enum.UserInputType | Enum.KeyCode | false?
	local msg = ScreenMessage("Info", "Press F4 to cancel keybinding.")
	ContextActionService:BindActionAtPriority("SelectKeybind", function(_, state, input)
		if state ~= Enum.UserInputState.End then
			return
		end

		if (input.KeyCode == Enum.KeyCode.F4) then
			ScreenMessage("Info", "Cancelled keybinding.")
			if msg then
				msg:Destroy()
			end
			ContextActionService:UnbindAction("SelectKeybind")

			result = false
			return
		end

		if msg then
			msg:Destroy()
		end

		ScreenMessage("Success", "Keybinding updated!")
		ContextActionService:UnbindAction("SelectKeybind")

		result = if input.KeyCode ~= Enum.KeyCode.Unknown then input.KeyCode else input.UserInputType
		return
	end, false, 100000, table.unpack(inputTypes))

	while result == nil do
		task.wait()
	end

	return if result then result else nil
end

local function updateDisplayedKeybind(frame: KeybindButton, kind: "Keyboard" | "Controller", key: Enum.UserInputType | Enum.KeyCode): ()
	local asString = ControlManager.GetStringForKeyCode(key)

	local bind = if kind == "Keyboard" then frame.Keyboard else frame.Controller
	if asString:sub(1, 11) == "rbxasset://" then
		local img = bind.KeycodeImage :: ImageLabel
		img.Image = asString
		img.Visible = true
		(bind.Keycode :: TextLabel).Visible = false
	else
		(bind.Keycode :: TextLabel).Text = asString;
		(bind.KeycodeImage :: ImageLabel).Visible = false
	end
end

local function setupKeybindButton(definition: SettingDefinitions.ControlDefinition, value: SettingDefinitions.ControlValue): KeybindButton
	local frame = buttonTemplates.KeybindSetting:Clone()
	frame.Label.Text = definition.Name .. ":"

	frame.Keyboard.Activated:Connect(function()
		local key = listenForInput(true)
		if key then
			Settings.UpdateControlSetting(definition.Name, {
				Kind = "KeyboardKeybind",
				New = key,
			})
			updateDisplayedKeybind(frame, "Keyboard", key)
		end
	end)

	frame.Controller.Activated:Connect(function()
		local key = listenForInput(false)
		if key then
			Settings.UpdateControlSetting(definition.Name, {
				Kind = "ControllerKeybind",
				New = key,
			})
			updateDisplayedKeybind(frame, "Controller", key)
		end
	end)

	return frame
end

local function setupForDefinition(definition: SettingDefinitions.SettingDefinition, value: SettingDefinitions.SettingValue)
	local button: GuiObject?
	if definition.Kind == "Boolean" then
		button = setupBooleanButton(definition, value :: SettingDefinitions.BooleanValue)
	elseif definition.Kind == "Choice" then
		button = setupChoiceButton(definition, value :: SettingDefinitions.ChoiceValue)
	elseif definition.Kind == "Control" then
		button = setupKeybindButton(definition, value :: SettingDefinitions.ControlValue)

		if definition.Default.TouchButton then
			module.AddClickButton(definition.Name .. " Position", "Touch", "Button Positions", function() end)
			module.AddClickButton(definition.Name .. " Scale", "Touch", "Button Sizes", function() end)
		end
	end

	assert(button, "Unknown definition kind: " .. definition.Kind)

	button.Name = "Setting_" .. definition.Name
	button.Visible = true

	button.Parent = ui.Object.PageHolder.ScrollingFrame
end

function module.AddClickButton(label: string, tab: string, category: string, onClick: () -> ()): ()
	local button = buttonTemplates.ClickButton:Clone()
	button.Name = "ClickButton_" .. label
	button.Visible = true
	button.Label.Text = label
	button.Activated:Connect(onClick)
	button.Parent = ui.Object.PageHolder.ScrollingFrame
end

function module.AddButton(definition: SettingDefinitions.SettingDefinition, value: SettingDefinitions.SettingValue): ()
	setupForDefinition(definition, value)
end

return module