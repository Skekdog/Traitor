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

local INPUT_PRIORITY = Enum.ContextActionPriority.Medium.Value
local REDUCED_INPUT_PRIORITY = Enum.ContextActionPriority.Medium.Value

local gamepad = {
	DPadDown = 0,
	DPadUp = 0,
	ButtonL2 = 0,
	ButtonR2 = 0,
	Thumbstick1 = Vector2.new(),
	Thumbstick2 = Vector2.new(),
}

local mouse = {
	Delta = Vector2.new(),
	MouseWheel = 0,
}

local function isKeyDown(key: string): number
	return if UserInputService:IsKeyDown(Enum.KeyCode:FromName(key) or error("Invalid key: " .. key)) then 1 else 0
end

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
		isKeyDown("D") - isKeyDown("A"),
		isKeyDown("E") - isKeyDown("Q"),
		isKeyDown("S") - isKeyDown("W")
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
	local kGamepad = (isKeyDown("ButtonX") - isKeyDown("ButtonY")) * FOV_GAMEPAD_SPEED
	local kMouse = mouse.MouseWheel * FOV_WHEEL_SPEED

	mouse.MouseWheel = 0

	return kGamepad + kMouse
end

local function MousePan(action: string, state: Enum.UserInputState, input: InputObject): Enum.ContextActionResult
	local delta = input.Delta
	mouse.Delta = Vector2.new(-delta.Y, -delta.X)
	return Enum.ContextActionResult.Sink
end

local function Thumb(action: string, state: Enum.UserInputState, input: InputObject): Enum.ContextActionResult
	gamepad[input.KeyCode.Name] = input.Position :: any
	return Enum.ContextActionResult.Sink
end

local function Trigger(action: string, state: Enum.UserInputState, input: InputObject): Enum.ContextActionResult
	gamepad[input.KeyCode.Name] = input.Position.Z
	return Enum.ContextActionResult.Sink
end

local function MouseWheel(action: string, state: Enum.UserInputState, input: InputObject): Enum.ContextActionResult
	mouse[input.UserInputType.Name] = -input.Position.Z
	return Enum.ContextActionResult.Sink
end

local function TouchPan(action: string, state: Enum.UserInputState, input: InputObject): Enum.ContextActionResult
	local delta = input.Delta

	-- Assume this is just a tap
	if delta.Magnitude < 1 then
		return Enum.ContextActionResult.Pass
	end

	mouse.Delta = Vector2.new(-delta.Y, -delta.X) * MOBILE_PAN_SENSITIVITY_MULTIPLIER
	return Enum.ContextActionResult.Sink
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

	ContextActionService:BindActionAtPriority("FreeInputMousePan",          MousePan,    false, INPUT_PRIORITY,         Enum.UserInputType.MouseMovement)
	ContextActionService:BindActionAtPriority("FreeInputTouchPan",          TouchPan,    false, REDUCED_INPUT_PRIORITY, Enum.UserInputType.Touch)
	ContextActionService:BindActionAtPriority("FreeInputMouseWheel",        MouseWheel,  false, INPUT_PRIORITY,         Enum.UserInputType.MouseWheel)
	ContextActionService:BindActionAtPriority("FreeInputGamepadTrigger",    Trigger,     false, INPUT_PRIORITY,         Enum.KeyCode.ButtonR2, Enum.KeyCode.ButtonL2)
	ContextActionService:BindActionAtPriority("FreeInputGamepadThumbstick", Thumb,       false, INPUT_PRIORITY,         Enum.KeyCode.Thumbstick1, Enum.KeyCode.Thumbstick2)
end

function module.StopCapture(): ()
	activeCapturers -= 1
	if activeCapturers ~= 0 then
		return
	end

	Zero(gamepad)
	Zero(mouse)
	ContextActionService:UnbindAction("FreeInputMousePan")
	ContextActionService:UnbindAction("FreeInputTouchPan")
	ContextActionService:UnbindAction("FreeInputMouseWheel")
	ContextActionService:UnbindAction("FreeInputGamepadTrigger")
	ContextActionService:UnbindAction("FreeInputGamepadThumbstick")
end

return module