local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Freecam = require(ReplicatedStorage.Shared.Camera.Freecam)
local UIAnimation = require(ReplicatedStorage.Shared.Interface.UILib.UIAnimation)
local UIManager = require(ReplicatedStorage.Shared.Interface.UILib.UIManager)
local ClientInventory = require(ReplicatedStorage.Shared.LocalState.ClientInventory)

local PlayerState = {}

local playerState = (UIManager.WaitForUI("LeftArea").Object :: typeof(UIManager.UnregisteredUIs.LeftArea)).PlayerState

local function showHealth(show: boolean): ()
    playerState.HealthBar.Visible = show
end

local function setHealth(hum: Humanoid)
    playerState.HealthBar.HealthLabel.Text = tostring(math.max(math.ceil(hum.Health), 0))
    UIAnimation.Slider(playerState.HealthBar.Background, false, hum.Health, hum.MaxHealth)
end

local healthCon: RBXScriptConnection?
local function onCameraUpdated(): ()
    local subject = workspace.CurrentCamera.CameraSubject
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

workspace.CurrentCamera:GetPropertyChangedSignal("CameraSubject"):Connect(onCameraUpdated)

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

function PlayerState.UpdateAmmo(): ()
    local item = ClientInventory.EquippedItem()
    if not item or not item.Ammo then
        playerState.AmmoBar.Visible = false
        return
    end

    local currentAmmo = item.Ammo
    if currentAmmo == math.huge then
        playerState.AmmoBar.Visible = false
        return
    end

    local maxAmmo: string | number = if item.AmmoDefinition then item.AmmoDefinition.Capacity else 0
    if maxAmmo == math.huge then
        maxAmmo = "∞"
    end

    local reserveString = ""
    if item.AmmoDefinition then
        reserveString = if item.AmmoDefinition.ReserveCapacity == 0 then "" else ` + {ClientInventory.GetReserveAmmo(item.AmmoDefinition.Name)}`
    end

    playerState.AmmoBar.Visible = true
    playerState.AmmoBar.AmmoLabel.Text = `{currentAmmo} / {maxAmmo}{reserveString}`
    UIAnimation.Slider(playerState.AmmoBar.Background, false, item.Ammo, if typeof(maxAmmo) == "number" then maxAmmo else math.huge)
end

function PlayerState.UpdatePunchMeter(punchMeter: number?, maxPunchMeter: number): ()
    if not punchMeter then
        playerState.PunchOMeter.Visible = false
        playerState.AmmoBar.Visible = false
        return
    end

    playerState.PunchOMeter.Visible = true
    playerState.AmmoBar.Visible = true
    playerState.AmmoBar.AmmoLabel.Text = ""
    UIAnimation.Slider(playerState.AmmoBar.Background, false, punchMeter, maxPunchMeter)
end

return PlayerState