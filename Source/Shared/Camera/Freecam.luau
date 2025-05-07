--!nonstrict
------------------------------------------------------------------------
-- Freecam
-- Cinematic free camera for spectating and video production.
------------------------------------------------------------------------

local pi    = math.pi
local clamp = math.clamp
local exp   = math.exp
local rad   = math.rad

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local FreeInput = require(ReplicatedStorage.Shared.Controls.FreeInput)

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
	Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
	LocalPlayer = Players.LocalPlayer
end

local Camera = Workspace.CurrentCamera
Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	local newCamera = Workspace.CurrentCamera
	if newCamera then
		Camera = newCamera
	end
end)

------------------------------------------------------------------------

local NAV_GAIN = Vector3.new(1, 1, 1)*64
local PAN_GAIN = Vector2.new(0.75, 1)*8

local PITCH_LIMIT = rad(90)

while Camera.ViewportSize.Magnitude < 10 do
	task.wait()
end

local VEL_STIFFNESS = 100.0 -- normal value is 1.5
local PAN_STIFFNESS = 100.0 -- normal value is 1.0

------------------------------------------------------------------------

local Spring = {} do
	Spring.__index = Spring

	function Spring.new(freq, pos)
		local self = setmetatable({}, Spring)
		self.f = freq
		self.p = pos
		self.v = pos*0
		return self
	end

	function Spring:Update(dt, goal)
		local f = self.f*2*pi
		local p0 = self.p
		local v0 = self.v

		local offset = goal - p0
		local decay = exp(-f*dt)

		local p1 = goal + (v0*dt - offset*(f*dt + 1))*decay
		local v1 = (f*dt*(offset*f - v0) + v0)*decay

		self.p = p1
		self.v = v1

		return p1
	end

	function Spring:Reset(pos)
		self.p = pos
		self.v = pos*0
	end
end

------------------------------------------------------------------------

local cameraPos = Vector3.new()
local cameraRot = Vector2.new()

local velSpring = Spring.new(VEL_STIFFNESS, Vector3.new())
local panSpring = Spring.new(PAN_STIFFNESS, Vector2.new())

------------------------------------------------------------------------

local function StepFreecam(dt)
	local vel = velSpring:Update(dt, FreeInput.GetVelocity(dt))
	local pan = panSpring:Update(dt, FreeInput.GetCameraPan(dt))

	cameraRot = cameraRot + pan*PAN_GAIN*(dt)
	cameraRot = Vector2.new(clamp(cameraRot.x, -PITCH_LIMIT, PITCH_LIMIT), cameraRot.y%(2*pi))

	local cameraCFrame = CFrame.new(cameraPos)*CFrame.fromOrientation(cameraRot.x, cameraRot.y, 0)*CFrame.new(vel*NAV_GAIN*dt)
	cameraPos = cameraCFrame.p

	Camera.CFrame = cameraCFrame
	Camera.Focus = cameraCFrame
end

------------------------------------------------------------------------

local PlayerState = {} do
	local mouseBehavior
	local cameraType
	local cameraFocus
	local cameraCFrame

	-- Save state and set up for freecam
	function PlayerState.Push()
		cameraType = Camera.CameraType
		Camera.CameraType = Enum.CameraType.Custom

		cameraCFrame = Camera.CFrame
		cameraFocus = Camera.Focus

		mouseBehavior = UserInputService.MouseBehavior
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	end

	-- Restore state
	function PlayerState.Pop()
		Camera.CameraType = cameraType
		cameraType = nil

		Camera.CFrame = cameraCFrame
		cameraCFrame = nil

		Camera.Focus = cameraFocus
		cameraFocus = nil

		UserInputService.MouseBehavior = mouseBehavior
		mouseBehavior = nil
	end
end

local freecamEnabled = false

local listeners: {(freecamEnabled: boolean) -> ()} = {}
local function ListenFreecamChanged(callback: (freecamEnabled: boolean) -> ()): ()
	table.insert(listeners, callback)
end

local function runCallbacks(): ()
	for _, callback in listeners do
		callback(freecamEnabled)
	end
end

local function StartFreecam(): ()
	if freecamEnabled then
		return
	end

	freecamEnabled = true

	local cameraCFrame = Camera.CFrame
	cameraRot = Vector2.new(cameraCFrame:toEulerAnglesYXZ())
	cameraPos = cameraCFrame.p + Vector3.new(1.5, 3, 0)

	velSpring:Reset(Vector3.new())
	panSpring:Reset(Vector2.new())

	PlayerState.Push()
	RunService:BindToRenderStep("Freecam", Enum.RenderPriority.Camera.Value, StepFreecam)
	FreeInput.StartCapture()

	runCallbacks()
end

local function StopFreecam(): ()
	if not freecamEnabled then
		return
	end

	freecamEnabled = false

	FreeInput.StopCapture()
	RunService:UnbindFromRenderStep("Freecam")
	PlayerState.Pop()

	runCallbacks()
end

local function ToggleFreecam(): boolean
	if freecamEnabled then
		StopFreecam()
	else
		StartFreecam()
	end
	return freecamEnabled
end

return {
	ToggleFreecam = ToggleFreecam,
	StartFreecam = StartFreecam,
	StopFreecam = StopFreecam,
	ListenFreecamChanged = ListenFreecamChanged,
}