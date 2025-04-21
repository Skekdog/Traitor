local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ClientInventory = require(ReplicatedStorage.ClientInventory)
local Freecam = require(ReplicatedStorage.Freecam)
local LocalRoundInfo = require(ReplicatedStorage.LocalRoundInfo)
local Types = require(ReplicatedStorage.RoundRule.Types)
local ToRoundTime = require(ReplicatedStorage.ToRoundTime)
local UIAnimation = require(ReplicatedStorage.UIAnimation)
local UIManager = require(ReplicatedStorage.UIManager)

local roundInfo = UIManager.WaitForUI("RoundInfo").Object :: typeof(UIManager.UnregisteredUIs.RoundInfo)

local module = {}

local timeTarget = LocalRoundInfo.AdvanceTime()
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

LocalRoundInfo.AdvanceTime:Connect(function(advanceTime)
    timeTarget = advanceTime
end)

LocalRoundInfo.Paused:Connect(function(_paused)
    lastTime = roundInfo.TopBar.Timer.Text
    paused = _paused
end)

LocalRoundInfo.PlayerRoles:Connect(function(roles)
    local roleValue = roles[Players.LocalPlayer.Name]
    local role = if roleValue then roleValue() else nil
    if role then
        roundInfo.TopBar.Role.Text = role:GetFormattedRoleName()
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

local healthCon: RBXScriptConnection?
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

    if healthCon then
        healthCon:Disconnect()
    end

    healthCon = subject.HealthChanged:Connect(function()
        setHealth(subject)
    end)
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

    local currentAmmo: string | number = item.Ammo
    if currentAmmo == math.huge then
        roundInfo.Frame.AmmoBar.Visible = false
        return
    end

    local maxAmmo: string | number = item.Definition.AmmoType.Capacity
    if maxAmmo == math.huge then
        maxAmmo = "∞"
    end

    local reserveString = if item.Definition.AmmoType.ReserveCapacity == 0 then "" else ` + {ClientInventory.GetReserveAmmo(item.Definition.AmmoType.Name)}`

    roundInfo.Frame.AmmoBar.Visible = true
    roundInfo.Frame.AmmoBar.AmmoLabel.Text = `{currentAmmo} / {maxAmmo}{reserveString}`
    UIAnimation.Slider(roundInfo.Frame.AmmoBar.Background, false, item.Ammo, item.Definition.AmmoType.Capacity)
end

return module