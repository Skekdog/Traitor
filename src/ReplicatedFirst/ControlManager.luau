--[[
	A middleware for CAS:BindAction() that integrates with SettingsManager to manage keybind and other setting changes appropriately.
	Stylises the Context Action Buttons also and decides if they should be toggled or held.
]]

local CS = game:GetService("CollectionService")
local CAS = game:GetService("ContextActionService")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local UIS = game:GetService("UserInputService")

local module = {}


local function getSetting(name: string)
	return ReplicatedFirst.SettingsManager.RequestSetting:Invoke(name)
end

type params = any
local registered: {[string]: params} = {}
local function onSettingUpdate(name, val)
	local setting = registered[name]
	if setting then
		module.Register(setting.actionName, setting.createTouchButton, setting.callback)
	end
end

function module.GetStringForKeyCode(keycode: Enum.KeyCode | Enum.UserInputType): string
	if keycode.EnumType == Enum.KeyCode then
		local img = UIS:GetImageForKeyCode(keycode :: Enum.KeyCode)
		if img ~= "" then return img end

		local str = UIS:GetStringForKeyCode(keycode :: Enum.KeyCode)
		if str ~= "" then return str end

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
		if keycode == Enum.UserInputType.MouseButton1 then return "LMB"
		elseif keycode == Enum.UserInputType.MouseButton2 then return "RMB"
		elseif keycode == Enum.UserInputType.MouseButton3 then return "MMB"
		elseif keycode == Enum.UserInputType.None then return "NONE"
		end
	end
	return keycode.Name
end

function module.SetupTouchButton(actionName)
	local butt = CAS:GetButton(actionName) :: ImageButton & {ActionTitle: TextLabel}
	if butt then
		butt.Position = getSetting(actionName.." Position")
		butt.Size = UDim2.fromScale(0.2, 0.2)
		butt.AnchorPoint = Vector2.one/2

		Instance.new("UIAspectRatioConstraint", butt)
		local scale = Instance.new("UIScale")
		scale.Scale = getSetting(actionName.." Scale")
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

		ReplicatedFirst.UIManager.UpdateThemeInstance:Fire(butt, nil, true)
		ReplicatedFirst.UIManager.UpdateThemeInstance:Fire(actionText, nil, true)
	end
end

function module.GetFirstKeyCode(actionName: string): string
	local keybindSetting = getSetting(actionName)
	local keybinds = keybindSetting.Keycodes
	if keybinds then
		return module.GetStringForKeyCode(keybinds[1][1])
	end
	return ""
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
		actionName = actionName,
		createTouchButton = createTouchButton,
		callback = callback
	}
	local keybindSetting = getSetting(actionName)
	local toggled = keybindSetting.Toggled
	local keybinds = keybindSetting.Keycodes
	
	local triggers = {}
	local modifiers = {}
	for _, v in keybinds do
		table.insert(triggers, v[1])
		modifiers[v[1]] = v[2]
	end
	CAS:BindAction(actionName, function(action, state, input: InputObject)
		local inp = input.KeyCode or input.UserInputType
		
		if (not modifiers[inp]) or (UIS:IsKeyDown(modifiers[inp])) then
			local show = false
			if (toggled) and (state == Enum.UserInputState.End) then show = true end
			if (not toggled) and ((state == Enum.UserInputState.Begin) or (state == Enum.UserInputState.End)) then show = true end

			if show then
				return callback(action, state, input, toggled)
			end
		end
		return Enum.ContextActionResult.Pass
	end, createTouchButton, table.unpack(triggers))
	
	module.SetupTouchButton(actionName)
	
	return CAS:GetButton(actionName)
end

function module.Unregister(actionName: string)
	CAS:UnbindAction(actionName)
	registered[actionName] = nil
end

ReplicatedFirst.SettingsManager.SettingUpdated.Event:Connect(onSettingUpdate)

return module