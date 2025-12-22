local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ControlManager = require(script.Parent.ControlManager)
local Controls = (require)(Players.LocalPlayer.PlayerScripts:WaitForChild("PlayerModule")):GetControls()

local UserGameSettings = UserSettings():GetService("UserGameSettings")

local module = {}

local NAV_GAMEPAD_SPEED = Vector3.new(1, 1, 1) * 2 -- normal value is * 1
local NAV_KEYBOARD_SPEED = Vector3.new(1, 1, 1) * 2 -- normal value is * 1
local FOV_WHEEL_SPEED = 1.5 -- normal value is 1.0
local FOV_GAMEPAD_SPEED = 0.25
local NAV_SHIFT_MUL = 0.25

local INPUT_PRIORITY = Enum.ContextActionPriority.Low.Value

local gamepad = {
	ButtonX = 0,
	ButtonY = 0,
	DPadDown = 0,
	DPadUp = 0,
	ButtonL2 = 0,
	ButtonR2 = 0,
	Thumbstick1 = Vector3.new(),
	Thumbstick2 = Vector3.new(),
}

local keyboard = {
	Forward = 0,
	Left = 0,
	Backward = 0,
	Right = 0,
	["Freecam Up"] = 0,
	["Freecam Down"] = 0,
	["Freecam Slow"] = 0,
}

local mouse = {
	Delta = Vector3.new(),
	MouseWheel = 0,
}

local touchDelta = Vector3.zero

local K_CURVATURE = 2.0
local K_DEADZONE = 0.15

-- Taken from PlayerModule.BaseCamera
local MIN_Y = math.rad(-80)
local MAX_Y = math.rad(80)

local ROTATION_SPEED_GAMEPAD = Vector3.new(1, 0.77)*math.rad(4) -- (rad/s)

-- these speeds should not be scaled by dt because the input returned is not normalized.
-- that is, at lower framerates, the magnitude of the input delta will be larger because the pointer/mouse/touch
-- has moved more pixels between frames.
local ROTATION_SPEED_MOUSE = Vector3.new(1, 0.77)*math.rad(0.5) -- (rad/inputdelta)
local ROTATION_SPEED_TOUCH = Vector3.new(1, 0.66)*math.rad(1) -- (rad/inputdelta)

local MIN_TOUCH_SENSITIVITY_FRACTION = 0.25 -- 25% sensitivity at 90°

local function fCurve(x: number)
	return (math.exp(K_CURVATURE * x) - 1) / (math.exp(K_CURVATURE) - 1)
end

local function fDeadzone(x: number)
	return fCurve((x - K_DEADZONE) / (1 - K_DEADZONE))
end

local function thumbstickCurve(x: number)
	return math.sign(x) * math.clamp(fDeadzone(math.abs(x)), 0, 1)
end

function module.GetVelocity(dt: number): Vector3
	local kGamepad = Vector3.new(
		thumbstickCurve(gamepad.Thumbstick1.X),
		thumbstickCurve(gamepad.ButtonR2) - thumbstickCurve(gamepad.ButtonL2),
		thumbstickCurve(-gamepad.Thumbstick1.Y)
	) * NAV_GAMEPAD_SPEED

	local kKeyboard = Vector3.new(
		keyboard.Right - keyboard.Left,
		keyboard["Freecam Up"] - keyboard["Freecam Down"],
		keyboard.Backward - keyboard.Forward
	) * NAV_KEYBOARD_SPEED

	local kTouch = Controls:GetMoveVector() :: Vector3

	local shift = keyboard["Freecam Slow"] > 0

	return ((kGamepad + kKeyboard + kTouch) * (if shift then NAV_SHIFT_MUL else 1)) * 60 * dt
end

-- Adjust the touch sensitivity so that sensitivity is reduced when swiping up
-- or down, but stays the same when swiping towards the middle of the screen
local function adjustTouchPitchSensitivity(delta: Vector3): Vector3
	local camera = workspace.CurrentCamera

	-- get the camera pitch in world space
	local pitch = camera.CFrame:ToEulerAnglesYXZ()

	if delta.Y * pitch >= 0 then
		-- do not reduce sensitivity when pitching towards the horizon
		return delta
	end

	-- set up a line to fit:
	-- 1 = f(0)
	-- 0 = f(±pi/2)
	local curveY = 1 - (2*math.abs(pitch)/math.pi)^0.75

	-- remap curveY from [0, 1] -> [MIN_TOUCH_SENSITIVITY_FRACTION, 1]
	local sensitivity = curveY*(1 - MIN_TOUCH_SENSITIVITY_FRACTION) + MIN_TOUCH_SENSITIVITY_FRACTION

	return Vector3.new(1, sensitivity) * delta
end

local function getRawCameraRotation(dt: number): Vector3
	local inversionVector = Vector3.new(1, UserGameSettings:GetCameraYInvertValue())

	local kGamepad = gamepad.Thumbstick2 * UserGameSettings.GamepadCameraSensitivity
	kGamepad *= dt

	local kMouse = mouse.Delta
	local kTouch = adjustTouchPitchSensitivity(touchDelta)

	local result =
		kGamepad * ROTATION_SPEED_GAMEPAD +
		kMouse * ROTATION_SPEED_MOUSE +
		kTouch * ROTATION_SPEED_TOUCH

	mouse.Delta = Vector3.zero

	return result * inversionVector
end

local function getConstrainedCameraRotateInput(dt: number): Vector3
	local rotateInput = getRawCameraRotation(dt)

	local currLookVector = workspace.CurrentCamera.CFrame.LookVector
	local currPitchAngle = math.asin(currLookVector.Y)
	local yTheta = math.clamp(rotateInput.Y, -MAX_Y + currPitchAngle, -MIN_Y + currPitchAngle)
	local constrainedRotateInput = Vector3.new(-yTheta, -rotateInput.X)

	return constrainedRotateInput
end

function module.GetCameraPan(dt: number): Vector3
	local result = getConstrainedCameraRotateInput(dt)
	return result
end

function module.GetFov(dt: number): number
	local kGamepad = (gamepad.ButtonX - gamepad.ButtonY) * FOV_GAMEPAD_SPEED
	local kMouse = mouse.MouseWheel * FOV_WHEEL_SPEED

	mouse.MouseWheel = 0

	return kGamepad + kMouse
end

local function Keypress(action: string, state: Enum.UserInputState, input: InputObject): Enum.ContextActionResult
	keyboard[action] = state == Enum.UserInputState.Begin and 1 or 0
	return Enum.ContextActionResult.Pass
end

local function GpButton(action: string, state: Enum.UserInputState, input: InputObject): Enum.ContextActionResult
	gamepad[input.KeyCode.Name] = state == Enum.UserInputState.Begin and 1 or 0
	return Enum.ContextActionResult.Pass
end

local function MousePan(action: string, state: Enum.UserInputState, input: InputObject): Enum.ContextActionResult
	mouse.Delta = input.Delta
	return Enum.ContextActionResult.Pass
end

local function Thumb(action: string, state: Enum.UserInputState, input: InputObject): Enum.ContextActionResult
	gamepad[input.KeyCode.Name] = input.Position :: any
	return Enum.ContextActionResult.Pass
end

local function Trigger(action: string, state: Enum.UserInputState, input: InputObject): Enum.ContextActionResult
	gamepad[input.KeyCode.Name] = input.Position.Z
	return Enum.ContextActionResult.Pass
end

local function MouseWheel(action: string, state: Enum.UserInputState, input: InputObject): Enum.ContextActionResult
	mouse[input.UserInputType.Name] = -input.Position.Z
	return Enum.ContextActionResult.Pass
end

local function TouchPan(input: InputObject): Enum.ContextActionResult
	local delta = input.Delta

	if input.UserInputState == Enum.UserInputState.Begin then
		local guiOccupying = false
		for _, object in Players.LocalPlayer.PlayerGui:GetGuiObjectsAtPosition(input.Position.X, input.Position.Y) do
			if object.Name == "DynamicThumbstickFrame" or object.BackgroundTransparency < 1 or ((object:IsA("ImageButton") or object:IsA("ImageLabel")) and object.ImageTransparency < 1) then
				guiOccupying = true
				break
			end
		end

		input:SetAttribute("Invalid", guiOccupying)
	end

	if input:GetAttribute("Invalid") then
		return Enum.ContextActionResult.Pass
	end

	touchDelta += Vector3.new(delta.X, delta.Y)
	return Enum.ContextActionResult.Pass
end

local function Zero(t: {[any]: any})
	for k, v in t do
		t[k] = v * 0
	end
end

local activeCapturers = 0
local inputBeganConn: RBXScriptConnection?
function module.StartCapture(): ()
	activeCapturers += 1
	if activeCapturers ~= 1 then
		return
	end

	ControlManager.Register("Forward", Keypress, INPUT_PRIORITY)
	ControlManager.Register("Left", Keypress, INPUT_PRIORITY)
	ControlManager.Register("Backward", Keypress, INPUT_PRIORITY)
	ControlManager.Register("Right", Keypress, INPUT_PRIORITY)
	ControlManager.Register("Freecam Up", Keypress, INPUT_PRIORITY)
	ControlManager.Register("Freecam Down", Keypress, INPUT_PRIORITY)
	ControlManager.Register("Freecam Slow", Keypress, INPUT_PRIORITY)

	-- Using CAS to detect touch fails when touching buttons, thus we have to do this
	if not inputBeganConn then
		inputBeganConn = UserInputService.InputBegan:Connect(function(input, proc)
			if input.UserInputType ~= Enum.UserInputType.Touch or proc then
				return
			end

			TouchPan(input)

			input:GetPropertyChangedSignal("Delta"):Connect(function()
				TouchPan(input)
			end)
		end)
	end

	RunService:BindToRenderStep("FreeInputResetTouchCameraPan", Enum.RenderPriority.Last.Value, function()
		touchDelta = Vector3.zero
	end)

	ContextActionService:BindActionAtPriority("FreeInputMousePan",          MousePan,    false, INPUT_PRIORITY,         Enum.UserInputType.MouseMovement)
	ContextActionService:BindActionAtPriority("FreeInputMouseWheel",        MouseWheel,  false, INPUT_PRIORITY,         Enum.UserInputType.MouseWheel)
	ContextActionService:BindActionAtPriority("FreeInputGamepadButton",     GpButton,    false, INPUT_PRIORITY,         Enum.KeyCode.ButtonX, Enum.KeyCode.ButtonY)
	ContextActionService:BindActionAtPriority("FreeInputGamepadTrigger",    Trigger,     false, INPUT_PRIORITY,         Enum.KeyCode.ButtonR2, Enum.KeyCode.ButtonL2)
	ContextActionService:BindActionAtPriority("FreeInputGamepadThumbstick", Thumb,       false, INPUT_PRIORITY,         Enum.KeyCode.Thumbstick1, Enum.KeyCode.Thumbstick2)
end

function module.StopCapture(): ()
	activeCapturers -= 1
	if activeCapturers ~= 0 then
		return
	end

	Zero(gamepad)
	Zero(keyboard)
	Zero(mouse)

	ControlManager.Unregister("Forward")
	ControlManager.Unregister("Left")
	ControlManager.Unregister("Backward")
	ControlManager.Unregister("Right")
	ControlManager.Unregister("Freecam Up")
	ControlManager.Unregister("Freecam Down")
	ControlManager.Unregister("Freecam Slow")

	ContextActionService:UnbindAction("FreeInputMousePan")
	ContextActionService:UnbindAction("FreeInputTouchPan")
	ContextActionService:UnbindAction("FreeInputMouseWheel")
	ContextActionService:UnbindAction("FreeInputGamepadButton")
	ContextActionService:UnbindAction("FreeInputGamepadTrigger")
	ContextActionService:UnbindAction("FreeInputGamepadThumbstick")

	if inputBeganConn then
		inputBeganConn:Disconnect()
		inputBeganConn = nil
	end

	RunService:UnbindFromRenderStep("FreeInputResetTouchCameraPan")
end

return module