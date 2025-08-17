local ContextActionService = game:GetService("ContextActionService")
local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local ControlManager = require(ReplicatedStorage.Shared.Controls.ControlManager)
local UIAnimation = require(ReplicatedStorage.Shared.Interface.UILib.UIAnimation)
local ScreenMessage = require(ReplicatedStorage.Shared.Interface.Util.ScreenMessage)
local TextInput = require(ReplicatedStorage.Shared.Interface.Util.TextInput)
local SettingDefinitions = require(script.Parent.SettingDefinitions)
local Settings = require(script.Parent.Settings)
local module = {}

local ui = ReplicatedStorage.Assets.UnregisteredUIs.Settings
module.UI = ui

local templates = ui.Main.Templates

type BooleanButton = typeof(templates.BooleanSetting)
type ChoiceButton = typeof(templates.ChoiceSetting)
type KeybindButton = typeof(templates.KeybindSetting)
type ClickButton = typeof(templates.ClickButton)
type Button = BooleanButton | ChoiceButton | KeybindButton | ClickButton

local CHECKBOX_ON = "rbxassetid://70556080680796"
local CHECKBOX_OFF = "rbxassetid://101035239747030"

local pageBase = templates.Page
type Page = typeof(templates.Page)

local pages: {[string]: Page?} = {}
local currentPage: Page? = nil

local tooltipObject = ui.Main.Tooltip
local function toggleTooltip(tooltip: string?): ()
	if not tooltip or tooltip == tooltipObject.Text then
		tooltipObject.Text = ""
		tooltipObject.Visible = false
		return
	end

	tooltipObject.Text = tooltip
	tooltipObject.Visible = true
end

local totalPages = 0
local function getPage(name: string): Page?
	return pages[name]
end

local function switchToPage(name: string): ()
	local newPage = pages[name]
	assert(newPage, `No page with name {name}`)

	if newPage == currentPage then
		return
	end

	if not currentPage then
		newPage.Visible = true
		currentPage = newPage
		return
	end

	UIAnimation.TransitionUIPage(currentPage, newPage, UDim2.new())
	currentPage = newPage
end

local function createPage(name: string): ()
	local page = pageBase:Clone()
	page.Name = "Page_" .. name
	page.Visible = false
	pages[name] = page
	page.Parent = ui.Main.PageHolder :: any

	page.LayoutOrder = totalPages

	totalPages += 1
end

local tabBase = templates.Tab
local function createTab(name: string): ()
	local tab = tabBase:Clone()
	tab.Name = "Tab_" .. name
	tab.Visible = true
	tab.Text = name
	tab.LayoutOrder = totalPages
	tab.Parent = ui.Main.TabHolder.Tabs :: any

	createPage(name)

	tab.Activated:Connect(function()
		switchToPage(name)
	end)
end

local categoryIndex: {[Page]: {[string]: number?}?} = {}
local function createCategoryLabel(name: string, page: Page): ()
	local label = templates.CategoryLabel:Clone()
	label.Text = name
	label.Name = "CategoryLabel_" .. name
	label.Visible = true
	
	if not categoryIndex[page] then
		categoryIndex[page] = {}
	end

	local index = categoryIndex[page]
	assert(index)
	
	local count = 0
	for _ in index do
		count += 1
	end

	local order = count * 1000
	index[name] = order

	label.LayoutOrder = index[name] :: number
	label.Parent = page :: any

	return 
end

local function getLayoutOrderForCategory(category: string, page: Page): number?
	local index = categoryIndex[page]
	if not index then
		return nil
	end
	return index[category]
end

local function setBooleanButton(button: BooleanButton, value: SettingDefinitions.BooleanValue): ()
	UIAnimation.TransitionSwitch(button.Value, value)
end

local function setBooleanValue(button: BooleanButton, definition: SettingDefinitions.BooleanDefinition, value: SettingDefinitions.BooleanValue)
	Settings.SetSetting(definition.Name, value)
	setBooleanButton(button, value)
end

local function setupBooleanButton(definition: SettingDefinitions.BooleanDefinition, value: SettingDefinitions.BooleanValue): BooleanButton
	local button = templates.BooleanSetting:Clone()
	button.Label.Text = definition.Name .. ":"

	button.Activated:Connect(function()
		setBooleanValue(button, definition, not Settings.GetSetting(definition.Name))
	end)

	setBooleanButton(button, value)

	return button
end

local function setChoiceButton(button: ChoiceButton, choiceButton: TextButton, value: SettingDefinitions.ChoiceValue): ()
	UIAnimation.TransitionUnderline(button.Choices.Underline, choiceButton)
end

local function setChoiceValue(button: ChoiceButton, choiceButton: TextButton, definition: SettingDefinitions.ChoiceDefinition, value: SettingDefinitions.ChoiceValue): ()
	Settings.SetSetting(definition.Name, value)
	setChoiceButton(button, choiceButton, value)
end

local function setupChoiceButton(definition: SettingDefinitions.ChoiceDefinition, value: SettingDefinitions.ChoiceValue): ChoiceButton
	local button = templates.ChoiceSetting:Clone()
	button.Label.Text = definition.Name .. ":"

	local choiceButton = button.Choices.Choice

	for i, choice in definition.PossibleValues do
		local but = choiceButton:Clone()
		but.Text = choice
		but.Visible = true

		but.Name = "Choice_" .. choice

		but.Position = UDim2.fromScale((i - 1) / #definition.PossibleValues + 0.1, 0.5)

		but.Activated:Connect(function()
			setChoiceValue(button, but, definition, choice)
		end)

		but.Parent = button.Choices

		if value == choice then
			task.defer(setChoiceButton, button, but, value)
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

local function updateDisplayedKeybind(frame: KeybindButton, kind: "Keyboard" | "Controller", key: Enum.UserInputType | Enum.KeyCode?): ()
	local asString = ControlManager.GetStringForKeyCode(key)

	local bind = if kind == "Keyboard" then frame.Keyboard else frame.Controller
	local imageLabel = bind.KeycodeImage :: ImageButton
	local textLabel = bind.Keycode :: TextButton

	if not key then
		textLabel.Visible = false
		imageLabel.Visible = false
		return
	end
	
	if asString:sub(1, 11) == "rbxasset://" then
		imageLabel.Image = asString
		imageLabel.Visible = true

		textLabel.Visible = false
	elseif asString ~= "NONE" then
		imageLabel.Visible = false

		textLabel.Text = asString
		textLabel.Visible = true
	end
end

local function updateDisplayedToggle(frame: KeybindButton, value: boolean): ()
	frame.Toggled.Image = if value then CHECKBOX_ON else CHECKBOX_OFF
end

local function updateKeybindToggled(frame: KeybindButton, definition: SettingDefinitions.ControlDefinition): ()
	local current = Settings.GetSetting(definition.Name) :: SettingDefinitions.ControlValue

	local new = not current.Toggled
	Settings.UpdateControlSetting(definition.Name, {
		Kind = "Toggled",
		New = new
	})

	updateDisplayedToggle(frame, new)
end

local function updateKeyboardKeybind(frame: KeybindButton, definition: SettingDefinitions.ControlDefinition, key: Enum.UserInputType | Enum.KeyCode?): ()
	Settings.UpdateControlSetting(definition.Name, {
		Kind = "KeyboardKeybind",
		New = key,
	})
	updateDisplayedKeybind(frame, "Keyboard", key)
end

local function promptUpdateKeyboardKeybind(frame: KeybindButton, definition: SettingDefinitions.ControlDefinition): ()
	local key = listenForInput(true)
	if key then
		updateKeyboardKeybind(frame, definition, key)
	end
end

local function updateControllerKeybind(frame: KeybindButton, definition: SettingDefinitions.ControlDefinition, key: Enum.UserInputType | Enum.KeyCode?): ()
	Settings.UpdateControlSetting(definition.Name, {
		Kind = "ControllerKeybind",
		New = key,
	})
	updateDisplayedKeybind(frame, "Controller", key)
end

local function promptUpdateControllerKeybind(frame: KeybindButton, definition: SettingDefinitions.ControlDefinition): ()
	local key = listenForInput(false)
	if key then
		updateControllerKeybind(frame, definition, key)
	end
end

local function setupKeybindButton(definition: SettingDefinitions.ControlDefinition, value: SettingDefinitions.ControlValue): KeybindButton
	local frame = templates.KeybindSetting:Clone()
	frame.Label.Text = definition.Name .. ":"

	updateDisplayedKeybind(frame, "Keyboard", value.Keybind.KBMKeybind)
	updateDisplayedKeybind(frame, "Controller", value.Keybind.ConsoleKeybind)

	frame.Toggled.Visible = definition.SpecifyToggle or false
	updateDisplayedToggle(frame, value.Toggled)

	frame.Keyboard.Keycode.Activated:Connect(function()
		updateKeyboardKeybind(frame, definition, nil)
	end)

	frame.Keyboard.KeycodeImage.Activated:Connect(function()
		updateKeyboardKeybind(frame, definition, nil)
	end)

	frame.Controller.Keycode.Activated:Connect(function()
		updateControllerKeybind(frame, definition, nil)
	end)

	frame.Controller.KeycodeImage.Activated:Connect(function()
		updateControllerKeybind(frame, definition, nil)
	end)

	frame.Keyboard.Activated:Connect(function()
		promptUpdateKeyboardKeybind(frame, definition)
	end)

	frame.Controller.Activated:Connect(function()
		promptUpdateControllerKeybind(frame, definition)
	end)

	frame.Toggled.Activated:Connect(function()
		updateKeybindToggled(frame, definition)
	end)

	return frame
end

local darken = ui.LayoutDarken

local function tempRegister(control: string, action: (button: ImageButton) -> ()): ()
	local lastParams = ControlManager.GetRegisteredInfo(control)
	local button = ControlManager.Register(control, function() return Enum.ContextActionResult.Pass end)

	assert(button)

	action(button)

	if lastParams then
		ControlManager.Register(control, lastParams.Callback, lastParams.Priority)
	else
		ControlManager.Unregister(control)
	end
end

local tapCon: RBXScriptConnection?
local function promptUpdateTouchPosition(control: string): UDim2?
	local position: UDim2?

	tempRegister(control, function(button: ImageButton): ()
		ui.Main.Visible = false
		toggleTooltip()
		darken.Visible = true

		task.wait() -- Waiting is necessary as otherwise the tap is detected when clicking the setting button
		tapCon = UserInputService.TouchTap:Connect(function(pos)
			local inset = GuiService:GetGuiInset()
			position = UDim2.fromOffset(inset.X + pos[1].X, inset.Y + pos[1].Y)
			button.Position = assert(position)
		end)

		darken.Done.Activated:Wait()

		assert(tapCon)
		tapCon:Disconnect()

		ui.Main.Visible = true
		darken.Visible = false
	end)

	return position
end

local function updateTouchPosition(definition: SettingDefinitions.ControlDefinition): ()
	if not UserInputService.TouchEnabled then
		return ScreenMessage("Info", "Touchscreen is not enabled on this device.")
	end

	local pos = promptUpdateTouchPosition(definition.Name)
	if pos then
		Settings.UpdateControlSetting(definition.Name, {
			Kind = "TouchPosition",
			New = pos,
		})
	end
end

local function updateTouchScale(definition: SettingDefinitions.ControlDefinition): ()
	if not UserInputService.TouchEnabled then
		return ScreenMessage("Info", "Touchscreen is not enabled on this device.")
	end

	tempRegister(definition.Name, function(button: ImageButton): ()
		local newScale = TextInput.Create(definition.Name, "Number", "0.5-3", "TouchScale")
		if newScale then
			Settings.UpdateControlSetting(definition.Name, {
				Kind = "TouchScale",
				New = newScale,
			})
		end
	end)
end

local function setupButton(buttonArg: Button, name: string, tab: string, category: string, tooltip: string?, addColon: boolean): ()
	local button = buttonArg :: ClickButton
	button.Label.Text = name .. if addColon then ":" else ""
	button.Name = "Button_" .. name
	button.Visible = true

	local page = getPage(tab)
	if not page then
		createTab(tab)
		if totalPages == 1 then
			switchToPage(tab)
		end
	end

	page = getPage(tab)
	assert(page)

	local order = getLayoutOrderForCategory(category, page)
	if not order then
		createCategoryLabel(category, page)
	end

	order = getLayoutOrderForCategory(category, page)
	assert(order)

	if tooltip then
		button.Help.Visible = true
		button.Help.Activated:Connect(function()
			toggleTooltip(tooltip)
		end)
	end

	button.LayoutOrder = order + 1

	button.Parent = page :: any or error("No page for tab " .. tab)
end

local function setupForDefinition(definition: SettingDefinitions.SettingDefinition, value: SettingDefinitions.SettingValue)
	local button: Button?
	if definition.Kind == "Boolean" then
		button = setupBooleanButton(definition, value :: SettingDefinitions.BooleanValue)
	elseif definition.Kind == "Choice" then
		button = setupChoiceButton(definition, value :: SettingDefinitions.ChoiceValue)
	elseif definition.Kind == "Control" then
		button = setupKeybindButton(definition, value :: SettingDefinitions.ControlValue)

		if definition.Default.TouchButton then
			module.AddClickButton(definition.Name .. " Position", "Touch", "Button Positions", nil, function()
				updateTouchPosition(definition)
			end)
			module.AddClickButton(definition.Name .. " Scale", "Touch", "Button Sizes", nil, function()
				updateTouchScale(definition)
			end)
		end
	end

	assert(button, "Unknown definition kind: " .. definition.Kind)

	setupButton(button :: Button, definition.Name, definition.Tab, definition.Category, definition.Tooltip, true)
end

function module.AddClickButton(label: string, tab: string, category: string, tooltip: string?, onClick: () -> ()): ()
	local button = templates.ClickButton:Clone()
	setupButton(button, label, tab, category, tooltip, false)
	button.Activated:Connect(onClick)
end

function module.AddButton(definition: SettingDefinitions.SettingDefinition, value: SettingDefinitions.SettingValue): ()
	setupForDefinition(definition, value)
end

function module.AdjustForInset(inset: Vector2): ()
	ui.LayoutDarken.Hint.Position = UDim2.new(0, inset.X, 0, inset.Y)
	ui.LayoutDarken.Done.Position = UDim2.new(0.5, inset.X, 0.1, inset.Y)
end

function module.UpdateButtonValue(definition: SettingDefinitions.SettingDefinition, value: SettingDefinitions.SettingValue): ()
	local page = getPage(definition.Tab)
	if not page then
		error("Invalid tab: " .. definition.Tab)
	end

	local button = page:FindFirstChild("Button_" .. definition.Name) :: Button
	if not button then
		error("Invalid button: " .. definition.Name)
	end

	if definition.Kind == "Boolean" then
		setBooleanButton(button :: BooleanButton, value :: SettingDefinitions.BooleanValue)
	elseif definition.Kind == "Choice" then
		setChoiceButton(button :: ChoiceButton, (button :: ChoiceButton).Choices:FindFirstChild("Choice_" .. value :: string) :: TextButton, value :: SettingDefinitions.ChoiceValue)
	elseif definition.Kind == "Control" then
		updateDisplayedKeybind(button :: KeybindButton, "Keyboard", (value :: SettingDefinitions.ControlValue).Keybind.KBMKeybind)
		updateDisplayedKeybind(button :: KeybindButton, "Controller", (value :: SettingDefinitions.ControlValue).Keybind.ConsoleKeybind)
	end
end

ui:GetPropertyChangedSignal("Visible"):Connect(function()
	if not ui.Visible then
		Settings.SaveSettings()
	end
end)

return module