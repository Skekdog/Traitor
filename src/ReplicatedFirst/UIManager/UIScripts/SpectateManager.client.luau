local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local plr = Players.LocalPlayer

local Freecam = require(script.Parent.Parent.Parent.Freecam)
local LocalRoundInfo = require(ReplicatedFirst.LocalRoundInfo)
local uiManager = require(ReplicatedFirst.UIManager)
local controls = require(ReplicatedFirst.ControlManager)

local camera = workspace.CurrentCamera
local ui = uiManager.WaitForUI("Spectate")
local uiO = ui.Object :: typeof(uiManager.UnregisteredUIs.Spectate)

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

local currentCameraMode: "Player" | "Freecam" = "Player"
LocalRoundInfo.Listen("IsSpectating", function(val)
	-- Do not early return here because we need to set camera properties always
	if ui.Visible ~= val then
		uiO.Username.Text = "Use buttons to spectate"
		lastKey = 0
	end
	
	if val then
		if currentCameraMode == "Player" then
			Freecam.StopFreecam()
		else
			Freecam.StartFreecam()
		end

		ui:ToggleVisible(true)
		camera.CameraType = Enum.CameraType.Track
		plr.CameraMode = Enum.CameraMode.Classic
		
		controls.Register("Spectate Next", false, spectateFunc)
		controls.Register("Spectate Previous", false, spectateFunc)
	else
		Freecam.StopFreecam()
		ui:ToggleVisible(false)
		camera.CameraType = Enum.CameraType.Custom
		plr.CameraMode = Enum.CameraMode.LockFirstPerson
		
		controls.Unregister("Spectate Next")
		controls.Unregister("Spectate Previous")
	end
end)

uiO.Forward.MouseButton1Click:Connect(function()
	spectateFunc("Spectate Next", Enum.UserInputState.End)
end)

uiO.Back.MouseButton1Click:Connect(function()
	spectateFunc("Spectate Previous", Enum.UserInputState.End)
end)

uiO.CameraMode.Activated:Connect(function()
	if currentCameraMode == "Player" then
		currentCameraMode = "Freecam"
	else
		currentCameraMode = "Player"
	end

	uiO.CameraMode.Text = "Camera Mode: " .. currentCameraMode

	if LocalRoundInfo.IsSpectating() then
		if currentCameraMode == "Player" then
			Freecam.StopFreecam()
		else
			Freecam.StartFreecam()
		end
	end
end)

LocalRoundInfo.SetSpectating(LocalRoundInfo.GetRoundPhase() ~= "Destroy")