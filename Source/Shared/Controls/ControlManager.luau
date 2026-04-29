local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local ControlTypes = require(script.Parent.ControlTypes)
local SettingDefinitions = require(ReplicatedStorage.Shared.Settings.SettingDefinitions)
local Settings = require(ReplicatedStorage.Shared.Settings.Settings)
local ActionButton = require(ReplicatedStorage.Shared.Interface.UILib.ActionButton)
local InstanceSignal = require(ReplicatedStorage.Shared.Util.InstanceSignal)

local module = {}

export type RegistrationInfo = {
	ActionName: string,
	Priority: number,
	Callback: ControlTypes.ActionCallback,
}

export type InputMethod = "Touch" | "KBM" | "Gamepad"

local registered: {[string]: RegistrationInfo} = {}

local KEY_NAMES = {
	LeftControl = "LCTRL",
	RightControl = "RCTRL",
	LeftAlt = "LALT",
	RightAlt = "RALT",
	LeftShift = "LSHIFT",
	RightShift = "RSHIFT",
	Tab = "TAB",
	Space = "SPACE",
	Return = "ENTER",
}

module.PreferredInput = InstanceSignal.ListenProperty(UserInputService, "PreferredInput", (nil :: any) :: Enum.PreferredInput)

function module.GetStringForKeyCode(keycode: Enum.KeyCode | Enum.UserInputType?): string
	if not keycode then
		return "NONE"
	end
	if keycode.EnumType == Enum.KeyCode then
		local img = UserInputService:GetImageForKeyCode(keycode :: Enum.KeyCode)
		if img ~= "" then
			return img
		end

		local str = UserInputService:GetStringForKeyCode(keycode :: Enum.KeyCode)
		if str ~= "" and str ~= " " then
			if str:sub(1, 6) == "Button" then
				return `\{{str:sub(7, -1)}\}`
			end
			return str
		end

		if keycode.Name:sub(1, 1) == "F" and tonumber(keycode.Name:sub(2)) then
			return keycode.Name
		elseif KEY_NAMES[keycode.Name] then
			return KEY_NAMES[keycode.Name]
		end
	else
		if keycode == Enum.UserInputType.MouseButton1 then
			return "LMB"
		elseif keycode == Enum.UserInputType.MouseButton2 then
			return "RMB"
		elseif keycode == Enum.UserInputType.MouseButton3 then
			return "MMB"
		elseif keycode == Enum.UserInputType.None then
			return "NONE"
		end
	end
	return keycode.Name
end

function module.GetFirstKeyCode(actionName: string, blankForTouch: boolean?): string
	local controlSetting = Settings.GetSetting(actionName) :: Settings.ControlValue
	local keybinds = controlSetting.Keybind

	local preferred = module.PreferredInput()
	if preferred == Enum.PreferredInput.Touch then
		return if blankForTouch then "" else actionName
	end

	if not keybinds then
		return "NONE"
	end

	if preferred == Enum.PreferredInput.Gamepad and keybinds.Gamepad then
		return module.GetStringForKeyCode(keybinds.Gamepad)
	elseif preferred == Enum.PreferredInput.KeyboardAndMouse and keybinds.KBMKeybind then
		return module.GetStringForKeyCode(keybinds.KBMKeybind)
	end

	return "NONE"
end

-- Returns the Button if it was created
function module.Register(actionName: string, callback: ControlTypes.ActionCallback, priority: number?, settingOverride: Settings.ControlValue?): ActionButton.ActionButton?
	priority = priority or Enum.ContextActionPriority.Medium.Value
	assert(priority)

	if registered[actionName] then
		ContextActionService:UnbindAction(actionName)
	end

	registered[actionName] =  {
		ActionName = actionName,
		Callback = callback,
		Priority = priority,
	}

	local setting = settingOverride or Settings.GetSetting(actionName) :: Settings.ControlValue

	local toggled = setting.Toggled

	local binds: {Enum.KeyCode | Enum.UserInputType} = {}
	if setting.Keybind.Gamepad then
		table.insert(binds, setting.Keybind.Gamepad)
	end

	if setting.Keybind.KBMKeybind then
		table.insert(binds, setting.Keybind.KBMKeybind)
	end

	local function runCallback(action: string, state: Enum.UserInputState, input: InputObject): Enum.ContextActionResult
		if toggled then
			if state ~= Enum.UserInputState.Begin then
				return Enum.ContextActionResult.Pass
			end
		elseif state ~= Enum.UserInputState.Begin and state ~= Enum.UserInputState.End then
			return Enum.ContextActionResult.Pass
		end

		return callback(action, state, input)
	end

	ContextActionService:BindActionAtPriority(actionName, runCallback, false, priority, table.unpack(binds))

	if module.PreferredInput() == Enum.PreferredInput.Touch and setting.TouchButton then
		return ActionButton.ShowActionButton(actionName, runCallback, setting)
	end

	return nil
end

module.PreferredInput:Connect(function(preferred)
	for actionName, info in registered do
		local setting = Settings.GetSetting(actionName) :: Settings.ControlValue
		if setting.TouchButton then
			if preferred == Enum.PreferredInput.Touch then
				ActionButton.ShowActionButton(actionName, info.Callback, setting)
			else
				ActionButton.TryHideActionButton(actionName)
			end
		end
	end
end)

function module.Unregister(actionName: string)
	ContextActionService:UnbindAction(actionName)
	ActionButton.TryHideActionButton(actionName)
	registered[actionName] = nil
end

function module.GetRegisteredInfo(actionName: string): RegistrationInfo?
	return registered[actionName]
end

function module.TryUpdateRegisteredAction(name: string, value: SettingDefinitions.ControlValue): ()
	local info = module.GetRegisteredInfo(name)
	if info then
		module.Register(name, info.Callback, info.Priority)
	end
end

local function isKeyActive(key: Enum.KeyCode | Enum.UserInputType): boolean
	if key then
		if key:IsA("KeyCode") then
			if UserInputService:IsKeyDown(key) then
				return true
			end
		else
			if UserInputService:IsMouseButtonPressed(key) then
				return true
			end
		end
	end

	return false
end

function module.IsActionActive(actionName: string): boolean
	local setting = Settings.GetSetting(actionName) :: Settings.ControlValue

	local kbmKey = setting.Keybind.KBMKeybind
	local gamepadKey = setting.Keybind.Gamepad

	if kbmKey and isKeyActive(kbmKey) then
		return true
	end

	if gamepadKey and isKeyActive(gamepadKey) then
		return true
	end

	local button = ActionButton.GetButton(actionName)
	if button and button.GuiState == Enum.GuiState.Press then
		return true
	end

	return false
end

return table.freeze(module)