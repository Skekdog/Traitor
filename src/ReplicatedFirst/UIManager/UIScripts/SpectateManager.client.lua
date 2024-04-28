local Players = game:GetService("Players")
local plr = Players.LocalPlayer

local uiManager = require(game:GetService("ReplicatedFirst").UIManager)
local controls = require(game:GetService("ReplicatedFirst").ControlManager)

local camera = workspace.CurrentCamera
local ui = uiManager.WaitForUI("Spectate")
local uiO = ui.UI

local function spectateFunc(action,state)
	local chars = {}
	for _,v in Players:GetPlayers() do
		local char = v.Character
		if char then
			local hum = char:FindFirstChildOfClass("Humanoid")
			if hum then
				if hum.Health > 0 then
					table.insert(chars,hum)
				end
			end
		end
	end
	
	if #chars == 0 then
		uiO.Username.Text = "Nobody to spectate :("
		return
	end

	local lastKey = nil
	for i,v in chars do
		if v == camera.CameraSubject then
			lastKey = i
		end
	end
	
	if action == "Spectate Next" then
		if lastKey == #chars or not lastKey then lastKey = 0 end
		camera.CameraSubject = chars[lastKey+1]
	elseif action == "Spectate Previous" then
		if not lastKey then lastKey = 2 end
		if lastKey == 1 then lastKey = #chars + 1 end
		camera.CameraSubject = chars[lastKey-1]
	end
	
	uiO.Username.Text = camera.CameraSubject.Parent.Name
end

local clientStorage = (game :: any).ClientStorage
clientStorage:GetAttributeChangedSignal("IsSpectating"):Connect(function()
	uiO.Username.Text = "Use buttons to spectate"
	if clientStorage:GetAttribute("IsSpectating") then
		ui:ToggleVisible(true)
		camera.CameraType = Enum.CameraType.Track
		plr.CameraMode = Enum.CameraMode.Classic
		
		controls.Register("Spectate Next", false, spectateFunc)
		controls.Register("Spectate Previous", false, spectateFunc)
	else
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