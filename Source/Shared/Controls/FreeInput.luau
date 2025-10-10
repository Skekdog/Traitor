local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Controls = (require)(Players.LocalPlayer.PlayerScripts:WaitForChild("PlayerModule")):GetControls()

local module = {}

local MOBILE_PAN_SENSITIVITY_MULTIPLIER = 4
local NAV_GAMEPAD_SPEED = Vector3.new(1, 1, 1) * 2 -- normal value is * 1
local NAV_KEYBOARD_SPEED = Vector3.new(1, 1, 1) * 2 -- normal value is * 1
local PAN_MOUSE_SPEED = Vector2.new(1, 1) * (math.pi / 64)
local PAN_GAMEPAD_SPEED = Vector2.new(1, 1) * (math.pi / 8)
local FOV_WHEEL_SPEED = 1.5 -- normal value is 1.0
local FOV_GAMEPAD_SPEED = 0.25
local NAV_SHIFT_MUL = 0.25

local INPUT_PRIORITY = Enum.ContextActionPriority.Low.Value
local REDUCED_INPUT_PRIORITY = Enum.ContextActionPriority.Low.Value

local gamepad = {
	ButtonX = 0,
	ButtonY = 0,
	DPadDown = 0,
	DPadUp = 0,
	ButtonL2 = 0,
	ButtonR2 = 0,
	Thumbstick1 = Vector2.new(),
	Thumbstick2 = Vector2.new(),
}

local keyboard = {
	W = 0,
	A = 0,
	S = 0,
	D = 0,
	E = 0,
	Q = 0,
	LeftShift = 0,
	RightShift = 0,
}

local mouse = {
	Delta = Vector2.new(),
	MouseWheel = 0,
}

local K_CURVATURE = 2.0
		local K_DEADZONE = 0.15

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
		keyboard.D - keyboard.A,
		keyboard.E - keyboard.Q,
		keyboard.S - keyboard.W
	) * NAV_KEYBOARD_SPEED

	local kTouch = Controls:GetMoveVector() :: Vector3

	local shift = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.RightShift)

	return ((kGamepad + kKeyboard + kTouch) * (if shift then NAV_SHIFT_MUL else 1)) * 60 * dt
end

-- we don't actually need deltatime here because mouse.Delta is... well it's a delta
function module.GetCameraPan(): Vector2
	local kGamepad = Vector2.new(
		thumbstickCurve(gamepad.Thumbstick2.Y),
		thumbstickCurve(-gamepad.Thumbstick2.X)
	) * PAN_GAMEPAD_SPEED

	local kMouse = mouse.Delta * PAN_MOUSE_SPEED

	mouse.Delta = Vector2.new()

	return kGamepad + kMouse
end

function module.GetFov(dt: number): number
	local kGamepad = (gamepad.ButtonX - gamepad.ButtonY) * FOV_GAMEPAD_SPEED
	local kMouse = mouse.MouseWheel * FOV_WHEEL_SPEED

	mouse.MouseWheel = 0

	return kGamepad + kMouse
end

local function Keypress(action: string, state: Enum.UserInputState, input: InputObject): Enum.ContextActionResult
	keyboard[input.KeyCode.Name] = state == Enum.UserInputState.Begin and 1 or 0
	return Enum.ContextActionResult.Pass
end

local function GpButton(action: string, state: Enum.UserInputState, input: InputObject): Enum.ContextActionResult
	gamepad[input.KeyCode.Name] = state == Enum.UserInputState.Begin and 1 or 0
	return Enum.ContextActionResult.Pass
end

local function MousePan(action: string, state: Enum.UserInputState, input: InputObject): Enum.ContextActionResult
	local delta = input.Delta
	mouse.Delta = Vector2.new(-delta.Y, -delta.X)
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

local function TouchPan(action: string, state: Enum.UserInputState, input: InputObject): Enum.ContextActionResult
	local delta = input.Delta

	-- Assume this is just a tap
	if delta.Magnitude < 1 then
		return Enum.ContextActionResult.Pass
	end

	mouse.Delta = Vector2.new(-delta.Y, -delta.X) * MOBILE_PAN_SENSITIVITY_MULTIPLIER
	return Enum.ContextActionResult.Pass
end

local function Zero(t: {[any]: any})
	for k, v in t do
		t[k] = v * 0
	end
end

local activeCapturers = 0
function module.StartCapture(): ()
	activeCapturers += 1
	if activeCapturers ~= 1 then
		return
	end

	ContextActionService:BindActionAtPriority("FreeInputKeyboard", Keypress, false, INPUT_PRIORITY,
		Enum.KeyCode.W,
		Enum.KeyCode.A,
		Enum.KeyCode.S,
		Enum.KeyCode.D,
		Enum.KeyCode.E,
		Enum.KeyCode.Q
	)
	ContextActionService:BindActionAtPriority("FreeInputMousePan",          MousePan,    false, INPUT_PRIORITY,         Enum.UserInputType.MouseMovement)
	ContextActionService:BindActionAtPriority("FreeInputTouchPan",          TouchPan,    false, REDUCED_INPUT_PRIORITY, Enum.UserInputType.Touch)
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
	ContextActionService:UnbindAction("FreeInputKeyboard")
	ContextActionService:UnbindAction("FreeInputMousePan")
	ContextActionService:UnbindAction("FreeInputTouchPan")
	ContextActionService:UnbindAction("FreeInputMouseWheel")
	ContextActionService:UnbindAction("FreeInputGamepadButton")
	ContextActionService:UnbindAction("FreeInputGamepadTrigger")
	ContextActionService:UnbindAction("FreeInputGamepadThumbstick")
end

return module