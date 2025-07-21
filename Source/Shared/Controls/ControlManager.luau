local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local SettingDefinitions = require(ReplicatedStorage.Shared.Settings.SettingDefinitions)
local Settings = require(ReplicatedStorage.Shared.Settings.Settings)
local ActionButton = require(ReplicatedStorage.Shared.Interface.UILib.ActionButton)

local module = {}

export type ActionCallback = (actionName: string, state: Enum.UserInputState, input: InputObject) -> Enum.ContextActionResult
export type RegistrationInfo = {
	ActionName: string,
	Priority: number,
	Callback: ActionCallback,
}

export type InputMethod = "Touch" | "Keyboard" | "Controller"

local registered: {[string]: RegistrationInfo} = {}

function module.GetPreferredInputMethod(): InputMethod
	if UserInputService.GamepadEnabled then
		return "Controller"
	elseif UserInputService.KeyboardEnabled then
		return "Keyboard"
	elseif UserInputService.TouchEnabled then
		return "Touch"
	end
	error("No valid input methods!")
end

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
		if str ~= "" then
			if str:sub(1, 6) == "Button" then
				return `\{{str:sub(7, -1)}\}`
			end
			return str
		end

		if keycode == Enum.KeyCode.LeftControl then
			return "Ctrl"
		elseif keycode == Enum.KeyCode.LeftShift then
			return "Shift"
		elseif keycode == Enum.KeyCode.LeftAlt then
			return "Alt"
		elseif keycode == Enum.KeyCode.RightControl then
			return "RAlt"
		elseif keycode == Enum.KeyCode.RightShift then
			return "RShift"
		elseif keycode == Enum.KeyCode.RightAlt then
			return "RAlt"
		elseif keycode == Enum.KeyCode.Tab then
			return "Tab"
		elseif (keycode.Name:sub(1, 1) == "F") and (tonumber(keycode.Name:sub(2))) then
			return keycode.Name
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

	local preferred: InputMethod = module.GetPreferredInputMethod()
	if preferred == "Touch" then
		return if blankForTouch then "" else actionName
	end

	if not keybinds then
		return "NONE"
	end

	if preferred == "Controller" and keybinds.ConsoleKeybind then
		return module.GetStringForKeyCode(keybinds.ConsoleKeybind)
	elseif preferred == "Keyboard" and keybinds.KBMKeybind then
		return module.GetStringForKeyCode(keybinds.KBMKeybind)
	end

	if UserInputService.GamepadEnabled and keybinds.ConsoleKeybind then
		return module.GetStringForKeyCode(keybinds.ConsoleKeybind)
	elseif UserInputService.KeyboardEnabled and keybinds.KBMKeybind then
		return module.GetStringForKeyCode(keybinds.KBMKeybind)
	end

	return "NONE"
end

-- Returns the Button if it was created
function module.Register(actionName: string, callback: ActionCallback, priority: number?, settingOverride: Settings.ControlValue?): ActionButton.ActionButton?
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
	if setting.Keybind.ConsoleKeybind then
		table.insert(binds, setting.Keybind.ConsoleKeybind)
	end

	if setting.Keybind.KBMKeybind then
		table.insert(binds, setting.Keybind.KBMKeybind)
	end

	local function runCallback(action: string, state: Enum.UserInputState, input: InputObject): Enum.ContextActionResult
		if toggled then
			if state ~= Enum.UserInputState.End then
				return Enum.ContextActionResult.Pass
			end
		elseif state ~= Enum.UserInputState.Begin and state ~= Enum.UserInputState.End then
			return Enum.ContextActionResult.Pass
		end

		return callback(action, state, input)
	end

	ContextActionService:BindActionAtPriority(actionName, runCallback, false, priority, table.unpack(binds))
	
	if module.GetPreferredInputMethod() == "Touch" and setting.TouchButton then
		return ActionButton.ShowActionButton(actionName, runCallback)
	end

	return nil
end

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
	local consoleKey = setting.Keybind.ConsoleKeybind

	if kbmKey and isKeyActive(kbmKey) then
		return true
	end

	if consoleKey and isKeyActive(consoleKey) then
		return true
	end

	local button = ActionButton.GetButton(actionName)
	if button and button.GuiState == Enum.GuiState.Press then
		return true
	end

	return false
end

return module