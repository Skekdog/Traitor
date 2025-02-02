local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Freecam = require(ReplicatedStorage.Freecam)
local LocalRoundInfo = require(ReplicatedStorage.LocalRoundInfo)
local Types = require(ReplicatedStorage.RoundRule.Types)
local ToRoundTime = require(ReplicatedStorage.ToRoundTime)
local UIAnimation = require(ReplicatedStorage.UIAnimation)
local UIManager = require(ReplicatedStorage.UIManager)

local roundInfo = UIManager.WaitForUI("RoundInfo").Object :: typeof(UIManager.UnregisteredUIs.RoundInfo)

local module = {}

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

local function onCameraUpdated(): ()
    local subject = workspace.Camera.CameraSubject
    if not subject or not subject:IsA("Humanoid") or not subject:IsDescendantOf(workspace) then
        return showHealth(false)
    end

    local con: RBXScriptConnection
    con = subject.AncestryChanged:Connect(function()
        showHealth(subject:IsDescendantOf(workspace))

        if not subject:IsDescendantOf(workspace) then
            con:Disconnect()
        end
    end)

    showHealth(true)
    setHealth(subject)
end

workspace.Camera:GetPropertyChangedSignal("CameraSubject"):Connect(onCameraUpdated)

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
        onCameraUpdated()
    end
end)

function module.UpdateAmmo(item: Types.AnyItem?): ()
    if not item or item.Kind ~= "Gun" then
        roundInfo.Frame.AmmoBar.Visible = false
        return
    end

    roundInfo.Frame.AmmoBar.Visible = true
    roundInfo.Frame.AmmoBar.AmmoLabel.Text = `{item.Ammo} / {item.Definition.AmmoType.Capacity} + 0`
    UIAnimation.Slider(roundInfo.Frame.AmmoBar.Background, false, item.Ammo, item.Definition.AmmoType.Capacity)
end

return module