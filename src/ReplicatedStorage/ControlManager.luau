local CollectionService = game:GetService("CollectionService")
local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local SettingDefinitions = require(ReplicatedStorage.Settings.SettingDefinitions)
local Settings = require(ReplicatedStorage.Settings.Settings)
local ThemesManager = require(script.Parent.ThemesManager)

local module = {}

export type ActionCallback = (actionName: string, state: Enum.UserInputState, input: InputObject) -> Enum.ContextActionResult
export type RegistrationInfo = {
	ActionName: string,
	CreateTouchButton: boolean,
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

function module.SetupTouchButton(actionName)
	local butt = ContextActionService:GetButton(actionName) :: ImageButton & {ActionTitle: TextLabel}
	if not butt then
		return
	end

	local control = Settings.GetSetting(actionName) :: Settings.ControlValue
	assert(control.TouchButton, `{actionName} is not a touch control`)

	butt.Position = control.TouchButton.Position
	butt.Size = UDim2.fromScale(0.1, 0.1)
	butt.AnchorPoint = Vector2.one/2

	Instance.new("UIAspectRatioConstraint", butt)
	local scale = Instance.new("UIScale")
	scale.Scale = control.TouchButton.Scale
	scale.Parent = butt

	local actionText = butt.ActionTitle
	actionText.Text = actionName
	actionText.Size = UDim2.fromScale(0.9, 1)
	actionText.Position = UDim2.fromScale(0.5, 0)
	actionText.AnchorPoint = Vector2.xAxis/2
	actionText.TextScaled = true
	CollectionService:AddTag(actionText, "StyledUI")

	CollectionService:AddTag(butt, "StyledUI")
	butt:SetAttribute("Style", "Primary")
	butt:SetAttribute("UpdateImage", true)

	ThemesManager.UpdateThemeInstance(butt, nil, true)
	ThemesManager.UpdateThemeInstance(actionText, nil, true)
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
function module.Register(actionName: string, createTouchButton: boolean, callback: ActionCallback): ImageButton?
	if registered[actionName] then
		ContextActionService:UnbindAction(actionName)
	end

	registered[actionName] =  {
		ActionName = actionName,
		CreateTouchButton = createTouchButton,
		Callback = callback
	}

	local setting = Settings.GetSetting(actionName) :: Settings.ControlValue

	local toggled = setting.Toggled

	local binds: {Enum.KeyCode | Enum.UserInputType} = {}
	if setting.Keybind.ConsoleKeybind then
		table.insert(binds, setting.Keybind.ConsoleKeybind)
	end

	if setting.Keybind.KBMKeybind then
		table.insert(binds, setting.Keybind.KBMKeybind)
	end

	ContextActionService:BindAction(actionName, function(action, state, input): Enum.ContextActionResult
		if toggled then
			if state ~= Enum.UserInputState.End then
				return Enum.ContextActionResult.Pass
			end
		elseif state ~= Enum.UserInputState.Begin and state ~= Enum.UserInputState.End then
			return Enum.ContextActionResult.Pass
		end

		return callback(action, state, input)
	end, createTouchButton, table.unpack(binds))
	
	module.SetupTouchButton(actionName)
	
	return ContextActionService:GetButton(actionName)
end

function module.Unregister(actionName: string)
	ContextActionService:UnbindAction(actionName)
	registered[actionName] = nil
end

function module.GetRegisteredInfo(actionName: string): RegistrationInfo?
	return registered[actionName]
end

function module.TryUpdateRegisteredAction(name: string, value: SettingDefinitions.ControlValue): ()
	print(name, value)
	local info = module.GetRegisteredInfo(name)
	if info then
		module.Register(name, info.CreateTouchButton, info.Callback)
	end
end

return module