local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ClientInventory = require(ReplicatedStorage.Shared.LocalState.ClientInventory)
local Freecam = require(ReplicatedStorage.Shared.Camera.Freecam)
local LocalCharacter = require(ReplicatedStorage.Shared.Character.LocalCharacter)
local ToRoundTime = require(ReplicatedStorage.Shared.Grammar.ToRoundTime)
local UIAnimation = require(ReplicatedStorage.Shared.Interface.UILib.UIAnimation)
local UIManager = require(ReplicatedStorage.Shared.Interface.UILib.UIManager)
local ShowMessage = require(ReplicatedStorage.Shared.Interface.Util.ShowMessage)
local LocalParticipantInfo = require(ReplicatedStorage.Shared.LocalState.LocalParticipantInfo)
local LocalRoundInfo = require(ReplicatedStorage.Shared.LocalState.LocalRoundInfo)
local Defaults = require(ReplicatedStorage.Shared.RoundRule.Defaults)
local Types = require(ReplicatedStorage.Shared.RoundRule.Types)

local participant = LocalParticipantInfo.GetParticipant()

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

local function setRoleText(): ()
    local role = participant.Role()
    local status: Types.ParticipantStatus = participant.Status() :: Types.ParticipantStatus
    local phase: Types.Phase = LocalRoundInfo.Phase() :: Types.Phase

    if status ~= "Alive" then
        roundInfo.TopBar.Role.Text = "Spectating"
    elseif role ~= Defaults.Role then
        roundInfo.TopBar.Role.Text = role:GetFormattedName()
    else
        roundInfo.TopBar.Role.Text = phase
    end
end

participant.Status:Connect(setRoleText, true)
participant.Role:Connect(setRoleText, true)
LocalRoundInfo.Phase:Connect(setRoleText, true)

local function updateFreeKillStatus(): ()
    local hasReason = not not LocalRoundInfo.FreeKill()
    local hasCharacter = not not LocalCharacter.Character()
    roundInfo.FreeKill.Visible = hasCharacter and hasReason
end

LocalRoundInfo.FreeKill:Connect(function(reason)
    if reason and not roundInfo.FreeKill.Visible then
        ShowMessage(`Because you {reason}, you are now a free kill!`, "Chat")
    end
    updateFreeKillStatus()
end)

LocalCharacter.Character:Connect(updateFreeKillStatus)

local function showFreeKillIgnoreReason(show: boolean): ()
    local hasReason = not not LocalRoundInfo.FreeKill()
    local hasCharacter = not not LocalCharacter.Character()
    roundInfo.FreeKill.Visible = hasCharacter and (show or hasReason)
end

ClientInventory.EquippedItem:Connect(function(item)
    if not item then
        return showFreeKillIgnoreReason(false)
    end

    local role = participant.Role()
    if item.IsEvilItem and not role.Definition.IsEvil then
        return showFreeKillIgnoreReason(true)
    end

    showFreeKillIgnoreReason(false)
end)

local function showHealth(show: boolean): ()
    roundInfo.Frame.HealthBar.Visible = show
end

local function setHealth(hum: Humanoid)
    roundInfo.Frame.HealthBar.HealthLabel.Text = tostring(math.max(math.ceil(hum.Health), 0))
    UIAnimation.Slider(roundInfo.Frame.HealthBar.Background, false, hum.Health, hum.MaxHealth)
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

function module.UpdateAmmo(): ()
    local item = ClientInventory.EquippedItem()
    if not item or not item.Ammo then
        roundInfo.Frame.AmmoBar.Visible = false
        return
    end

    local currentAmmo = item.Ammo
    if currentAmmo == math.huge then
        roundInfo.Frame.AmmoBar.Visible = false
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

    roundInfo.Frame.AmmoBar.Visible = true
    roundInfo.Frame.AmmoBar.AmmoLabel.Text = `{currentAmmo} / {maxAmmo}{reserveString}`
    UIAnimation.Slider(roundInfo.Frame.AmmoBar.Background, false, item.Ammo, if typeof(maxAmmo) == "number" then maxAmmo else math.huge)
end

function module.UpdatePunchMeter(punchMeter: number?, maxPunchMeter: number): ()
    if not punchMeter then
        roundInfo.Frame.PunchOMeter.Visible = false
        roundInfo.Frame.AmmoBar.Visible = false
        return
    end

    roundInfo.Frame.PunchOMeter.Visible = true
    roundInfo.Frame.AmmoBar.Visible = true
    roundInfo.Frame.AmmoBar.AmmoLabel.Text = ""
    UIAnimation.Slider(roundInfo.Frame.AmmoBar.Background, false, punchMeter, maxPunchMeter)
end

return table.freeze(module)