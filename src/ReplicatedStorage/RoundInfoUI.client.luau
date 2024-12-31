local Players = game:GetService("Players")
local Freecam = require(script.Parent.Freecam)
local LocalRoundInfo = require(script.Parent.LocalRoundInfo)
local ToRoundTime = require(script.Parent.ToRoundTime)
local UIAnimation = require(script.Parent.UIAnimation)
local UIManager = require(script.Parent.UIManager)

local roundInfo = UIManager.WaitForUI("RoundInfo").Object :: typeof(UIManager.UnregisteredUIs.RoundInfo)

local timeTarget = LocalRoundInfo.GetAdvanceTime()
local paused = false
local lastTime = ""
local function updateTimer(time: number)
    if paused then
		if math.round(time) % 2 == 1 then
			roundInfo.TopBar.Timer.Text = "PAUSED"
		else
			roundInfo.TopBar.Timer.Text = lastTime
		end
		return
	end

	roundInfo.TopBar.Timer.Text = ToRoundTime(time, timeTarget or time)
end

task.spawn(function()
    while true do
        updateTimer(workspace:GetServerTimeNow())
        task.wait()
    end
end)

LocalRoundInfo.Listen("AdvanceTime", function()
    timeTarget = LocalRoundInfo.GetAdvanceTime()
end)

LocalRoundInfo.Listen("Paused", function()
    lastTime = roundInfo.TopBar.Timer.Text
    paused = LocalRoundInfo.IsPaused()
end)

LocalRoundInfo.Listen("PlayerRole", function()
    local role = LocalRoundInfo.GetPlayerRole(Players.LocalPlayer)
    if role then
        roundInfo.TopBar.Role.Text = role:GetFormattedName()
    else
        roundInfo.TopBar.Role.Text = "Spectator"
    end
end)

local function showHealth(show: boolean): ()
    roundInfo.Frame.HealthBar.Visible = show
end

local function setHealth(hum: Humanoid)
    roundInfo.Frame.HealthBar.HealthLabel.Text = tostring(math.ceil(hum.Health))
    UIAnimation.Slider(roundInfo.Frame.HealthBar.Background, false, hum.Health, hum.MaxHealth)
end

workspace.Camera:GetPropertyChangedSignal("CameraSubject"):Connect(function()
    local subject = workspace.Camera.CameraSubject
    if not subject or not subject:IsA("Humanoid") then
        return
    end

    subject.AncestryChanged:Connect(function(_, parent)
        showHealth(parent ~= nil)
    end)

    setHealth(subject)
end)

Players.LocalPlayer.CharacterAdded:Connect(function(char)
    local hum = char:WaitForChild("Humanoid")
    assert(hum:IsA("Humanoid"))

    hum.HealthChanged:Connect(function(health)
        setHealth(hum)
    end)
end)

Freecam.ListenFreecamChanged(function(freecamEnabled)
    if freecamEnabled then
        showHealth(false)
    else
        showHealth(true)
    end
end)