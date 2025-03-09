local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Settings = require(ReplicatedStorage.Settings.Settings)

local ui = ReplicatedStorage.UnregisteredUIs.ActionButtons

local baseButton = ui.BaseButton

export type ActionButton = typeof(baseButton)

local module = {}

local buttonConnections: {[ActionButton]: {RBXScriptConnection}} = {}

function module.GetButton(actionName: string): ActionButton?
	return ui:FindFirstChild("Button_" .. actionName) :: ActionButton?
end

local function setCallbacks(actionName: string, button: ActionButton, callback: (actionName: string, state: Enum.UserInputState, input: InputObject) -> Enum.ContextActionResult): ()
	if buttonConnections[button] then
		for _, v in buttonConnections[button] do
			v:Disconnect()
		end
	end

	buttonConnections[button] = {}
	table.insert(buttonConnections[button], button.InputBegan:Connect(function(input)
		callback(actionName, input.UserInputState, input)
	end))

	table.insert(buttonConnections[button], button.InputChanged:Connect(function(input)
		callback(actionName, input.UserInputState, input)
	end))

	table.insert(buttonConnections[button], button.Activated:Connect(function(input) -- note: we use Activated rather than InputEnded, because InputEnded fires if the user moves their finger to the button and then releases, even if they didn't start on the button.
		callback(actionName, input.UserInputState, input)
	end))
end

function module.ShowActionButton(actionName: string, callback: (actionName: string, state: Enum.UserInputState, input: InputObject) -> Enum.ContextActionResult): ActionButton
	local button = module.GetButton(actionName)
	if button then
		setCallbacks(actionName, button, callback)
		button.Visible = true
		return button
	end

	button = baseButton:Clone()
	assert(button)

	local control = Settings.GetSetting(actionName) :: Settings.ControlValue
	assert(control.TouchButton, `{actionName} is not a touch control`)

	button.Position = control.TouchButton.Position
	button.UIScale.Scale = control.TouchButton.Scale

	button.ActionTitle.Text = actionName

	button.Visible = true
	button.Name = "Button_" .. actionName
	button.Parent = ui

	setCallbacks(actionName, button, callback)	

	return button
end

function module.TryHideActionButton(actionName: string): ()
	local button = module.GetButton(actionName)
	if button then
		button.Visible = false
	end
end

return module