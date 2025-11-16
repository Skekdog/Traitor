local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local GetAssemblyMass = require(ReplicatedStorage.API.GetAssemblyMass)
local GetMapObject = require(ReplicatedStorage.API.GetMapObject)
local Types = require(ReplicatedStorage.API.Types)
local Freecam = require(ReplicatedStorage.Shared.Camera.Freecam)
local FreeInput = require(ReplicatedStorage.Shared.Controls.FreeInput)
local GetPrimaryPart = require(ReplicatedStorage.Shared.RoundRule.Common.GetPrimaryPart)

local IMPULSE_MULTIPLIER = 5
local VERTICAL_MULTIPLIER = 3
local MAX_PUNCHES = 5
local PUNCH_RATE = 1
local PUNCH_COOLDOWN = 0.1

local PossessProp = {}

local punchMeter = 0
local lastPunch = 0
local currentPossess: Types.MapObject?
local punchConnection: RBXScriptConnection?

local camera = workspace.CurrentCamera

local function possess(prop: Types.MapObject): ()
	currentPossess = prop
	punchMeter = 0
	ReplicatedStorage.Remotes.ClientServer.PossessProp:FireServer(prop)

	Freecam.StopFreecam()

	local primaryPart = GetPrimaryPart(prop)
	camera.CameraSubject = primaryPart
	camera.CameraType = Enum.CameraType.Custom

	FreeInput.StartCapture()

	punchConnection = RunService.PreSimulation:Connect(function(dt)
		if not primaryPart:IsDescendantOf(workspace) then
			PossessProp.Stop()
			return
		end

		if punchMeter < 1 then
			return
		end

		if lastPunch > os.clock() - PUNCH_COOLDOWN then
			return
		end

		local input = FreeInput.GetVelocity(dt)
		if input.Magnitude == 0 then
			return
		end

		local impulse = workspace.CurrentCamera.CFrame.Rotation * input
		impulse *= IMPULSE_MULTIPLIER * GetAssemblyMass(primaryPart)
		impulse *= Vector3.new(1, VERTICAL_MULTIPLIER, 1)

		lastPunch = os.clock()
		punchMeter = math.min(math.floor(punchMeter - 1), MAX_PUNCHES)

		primaryPart:ApplyImpulse(impulse)
	end)
end

function PossessProp.Stop(): ()
	ReplicatedStorage.Remotes.ClientServer.PossessProp:FireServer()
	camera.CameraType = Enum.CameraType.Scriptable
	camera.CameraSubject = nil
	currentPossess = nil

	if punchConnection then
		punchConnection:Disconnect()
	end
end

function PossessProp.TryPossess(part: BasePart): ()
	if part:IsGrounded() then
		return
	end

	local prop = GetMapObject(part, "Prop")
	if not prop then
		return
	end

	if currentPossess then
		if currentPossess == prop then
			return
		end

		PossessProp.Stop()
	end

	possess(prop)
end

RunService.Heartbeat:Connect(function(dt)
	punchMeter += PUNCH_RATE * dt
end)

return PossessProp