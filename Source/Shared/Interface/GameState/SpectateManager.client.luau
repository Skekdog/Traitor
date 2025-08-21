local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local plr = Players.LocalPlayer

local Freecam = require(ReplicatedStorage.Shared.Camera.Freecam)
local UIManager = require(ReplicatedStorage.Shared.Interface.UILib.UIManager)
local LocalParticipantInfo = require(ReplicatedStorage.Shared.LocalState.LocalParticipantInfo)

local participant = LocalParticipantInfo.GetParticipant()

local camera = workspace.CurrentCamera
local ui = UIManager.WaitForUI("Spectate")
local uiO = ui.Object :: typeof(UIManager.UnregisteredUIs.Spectate)

local isCurrentlySpectatingPleaseRefactorThisScript = false

local lastKey = 0
local function spectateFunc(action, state)
	local chars = {}
	for _, v in Players:GetPlayers() do
		local char = v.Character
		if char and v ~= plr then
			local hum = char:FindFirstChildOfClass("Humanoid")
			if hum and hum.Health > 0 then
				table.insert(chars, hum)
			end
		end
	end
	
	if #chars == 0 then
		uiO.Username.Text = "Nobody to spectate!"
		return Enum.ContextActionResult.Pass
	end

	camera.CameraType = Enum.CameraType.Track
	plr.CameraMode = Enum.CameraMode.Classic
	
	local index: number
	if action == "Spectate Next" then
		index = if chars[lastKey + 1] then lastKey + 1 else 1
	elseif action == "Spectate Previous" then
		index = if chars[lastKey - 1] then lastKey - 1 else #chars
	end
	lastKey = index
	camera.CameraSubject = chars[index]
	
	uiO.Username.Text = ((camera.CameraSubject :: Humanoid).Parent :: Instance).Name
	return Enum.ContextActionResult.Sink
end

local statusId = newproxy()
local currentCameraMode: "Player" | "Freecam" = "Freecam"
participant.Status:Connect(function(status)
	local thisStatusId = newproxy()
	statusId = thisStatusId

	local isSpectating = status ~= "Alive"
	if isCurrentlySpectatingPleaseRefactorThisScript == isSpectating then
		return
	end

	-- Do not early return here because we need to set camera properties always
	if ui.Visible ~= isSpectating then
		uiO.Username.Text = "Use buttons to spectate"
		lastKey = 0
	end

	if isSpectating then
		local corpse = workspace.Corpses:FindFirstChild(participant.Name)
		if corpse then
			local head = corpse:FindFirstChild("Head")
			if head and head:IsA("BasePart") then
				camera.CameraSubject = head
				task.wait(3)
				if statusId ~= thisStatusId then
					return -- don't change camera if something else has changed the state
				end
			end
		end

		if currentCameraMode == "Player" then
			Freecam.StopFreecam()
		else
			Freecam.StartFreecam()
		end

		ui:ToggleVisible(true)
		camera.CameraType = Enum.CameraType.Track
		plr.CameraMode = Enum.CameraMode.Classic
		isCurrentlySpectatingPleaseRefactorThisScript = true
	else
		Freecam.StopFreecam()
		ui:ToggleVisible(false)
		camera.CameraType = Enum.CameraType.Custom
		plr.CameraMode = Enum.CameraMode.LockFirstPerson
		isCurrentlySpectatingPleaseRefactorThisScript = false
	end
end, true)

uiO.Forward.MouseButton1Click:Connect(function()
	spectateFunc("Spectate Next", Enum.UserInputState.End)
end)

uiO.Back.MouseButton1Click:Connect(function()
	spectateFunc("Spectate Previous", Enum.UserInputState.End)
end)

local function switchCameraMode(mode: "Player" | "Freecam")
	currentCameraMode = mode

	uiO.CameraMode.Text = "Camera Mode: " .. currentCameraMode

	local status = participant.Status()
	if status ~= "Alive" then
		if currentCameraMode == "Player" then
			Freecam.StopFreecam()
		else
			Freecam.StartFreecam()
		end
	end
end

uiO.CameraMode.Activated:Connect(function()
	switchCameraMode(if currentCameraMode == "Player" then "Freecam" else "Player")
end)
switchCameraMode("Freecam")