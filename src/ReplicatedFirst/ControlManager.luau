--[[
	A middleware for CAS:BindAction() that integrates with SettingsManager to manage keybind and other setting changes appropriately.
	Stylises the Context Action Buttons also and decides if they should be toggled or held.
]]

local CS = game:GetService("CollectionService")
local CAS = game:GetService("ContextActionService")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local UIS = game:GetService("UserInputService")
local SettingsManager = require(script.Parent.SettingsManager)
local ThemesManager = require(script.Parent.ThemesManager)

local module = {}

type params = {
	ActionName: string,
	CreateTouchButton: boolean,
	Callback: (actionName: string, state: Enum.UserInputState, input: InputObject, toggled: boolean) -> Enum.ContextActionResult,
}
local registered: {[string]: params} = {}
function module.OnSettingUpdate(name, val)
	local setting = registered[name]
	if setting then
		module.Register(setting.ActionName, setting.CreateTouchButton, setting.Callback)
	end
end

export type InputMethod = "touch" | "keyboard" | "controller"
function module.GetPreferredInputMethod(): InputMethod
	if UIS.GamepadEnabled then
		return "controller"
	elseif UIS.KeyboardEnabled then
		return "keyboard"
	elseif UIS.TouchEnabled then
		return "touch"
	end
	error("No valid input methods!")
end

function module.GetStringForKeyCode(keycode: Enum.KeyCode | Enum.UserInputType?): string
	if not keycode then
		return "NONE"
	end
	if keycode.EnumType == Enum.KeyCode then
		-- local img = UIS:GetImageForKeyCode(keycode :: Enum.KeyCode)
		-- if img ~= "" then return img end

		local str = UIS:GetStringForKeyCode(keycode :: Enum.KeyCode)
		if str ~= "" then
			if str:sub(1, 6) == "Button" then
				return str:sub(7, -1)
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
	local butt = CAS:GetButton(actionName) :: ImageButton & {ActionTitle: TextLabel}
	if butt then
		butt.Position = SettingsManager.GetSetting(actionName.." Position") :: UDim2
		butt.Size = UDim2.fromScale(0.1, 0.1)
		butt.AnchorPoint = Vector2.one/2

		Instance.new("UIAspectRatioConstraint", butt)
		local scale = Instance.new("UIScale")
		scale.Scale = SettingsManager.GetSetting(actionName.." Scale") :: number
		scale.Parent = butt

		local actionText = butt.ActionTitle
		actionText.Text = actionName
		actionText.Size = UDim2.fromScale(0.9, 1)
		actionText.Position = UDim2.fromScale(0.5, 0)
		actionText.AnchorPoint = Vector2.xAxis/2
		actionText.TextScaled = true
		CS:AddTag(actionText, "StyledUI")

		CS:AddTag(butt, "StyledUI")
		butt:SetAttribute("Style", "Primary")
		butt:SetAttribute("StyleData", "UpdateImage")

		ThemesManager.UpdateThemeInstance(butt, nil, true)
		ThemesManager.UpdateThemeInstance(actionText, nil, true)
	end
end

function module.GetFirstKeyCode(actionName: string, blankForTouch: boolean?): string
	local keybindSetting = SettingsManager.GetSetting(actionName) :: SettingsManager.KeybindSetting
	local keybinds = keybindSetting.Keycodes

	local preferred: InputMethod = module.GetPreferredInputMethod()
	if preferred == "touch" then
		return if blankForTouch then "" else actionName
	end

	if not keybinds then
		return "NONE"
	end

	for _, key in keybinds do
		if preferred == "controller" and key:IsA("KeyCode") and key.Name:sub(1, 6) == "Button" then
			return module.GetStringForKeyCode(key)
		elseif preferred == "keyboard" and key.Name:sub(1, 6) ~= "Button" then
			return module.GetStringForKeyCode(key)
		end
	end

	-- If we didn't find our preferred method then we look for the first valid method
	for _, key in keybinds do
		if UIS.GamepadEnabled and key:IsA("KeyCode") and key.Name:sub(1, 6) == "Button" then
			return module.GetStringForKeyCode(key)
		elseif UIS.KeyboardEnabled and key.Name:sub(1, 6) ~= "Button" then
			return module.GetStringForKeyCode(key)
		end
	end

	return "NONE"
end

-- Returns the Button if it was created
function module.Register(actionName: string, createTouchButton: boolean, callback: (actionName: string, state: Enum.UserInputState, input: InputObject, toggled: boolean) -> Enum.ContextActionResult): ImageButton?
	if not ReplicatedFirst:GetAttribute("ControlsReady") then
		ReplicatedFirst:GetAttributeChangedSignal("ControlsReady"):Wait()
	end

	if registered[actionName] then
		CAS:UnbindAction(actionName)
	end

	registered[actionName] =  {
		ActionName = actionName,
		CreateTouchButton = createTouchButton,
		Callback = callback
	}
	local keybindSetting = SettingsManager.GetSetting(actionName) :: SettingsManager.KeybindSetting
	local toggled = keybindSetting.Toggled
	local keybinds = keybindSetting.Keycodes

	CAS:BindAction(actionName, function(action, state, input)
		local show = false

		if (toggled) and (state == Enum.UserInputState.End) then
			show = true
		end

		if (not toggled) and ((state == Enum.UserInputState.Begin) or (state == Enum.UserInputState.End)) then
			show = true
		end

		if show then
			return callback(action, state, input, toggled)
		end
		return Enum.ContextActionResult.Pass
	end, createTouchButton, table.unpack(keybinds))
	
	module.SetupTouchButton(actionName)
	
	return CAS:GetButton(actionName)
end

function module.Unregister(actionName: string)
	CAS:UnbindAction(actionName)
	registered[actionName] = nil
end

return module