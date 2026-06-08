local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ToRoundTime = require(ReplicatedStorage.Shared.Grammar.ToRoundTime)
local UIManager = require(ReplicatedStorage.Shared.Interface.UILib.UIManager)
local LocalParticipantInfo = require(ReplicatedStorage.Shared.LocalState.LocalParticipantInfo)
local LocalRoundInfo = require(ReplicatedStorage.Shared.LocalState.LocalRoundInfo)
local Defaults = require(ReplicatedStorage.Shared.RoundRule.Defaults)
local Types = require(ReplicatedStorage.API.Types)

local participant = LocalParticipantInfo.GetParticipant()

local roundInfo = (UIManager.WaitForUI("LeftArea").Object :: typeof(UIManager.UnregisteredUIs.LeftArea)).RoundInfo

local module = {}

local timeTarget = LocalRoundInfo.AdvanceTime()
local paused = false
local lastTime = ""
local function updateTimer(time: number)
    if paused then
		if math.round(time) % 2 == 1 then
			roundInfo.Timer.Text = "PAUSED"
		else
			roundInfo.Timer.Text = lastTime
		end
		return
	end

	roundInfo.Timer.Text = ToRoundTime(time, timeTarget or time)
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
    lastTime = roundInfo.Timer.Text
    paused = _paused
end)

local function setRoleText(): ()
    local role = participant.Role()
    local status: Types.ParticipantStatus = participant.Status() :: Types.ParticipantStatus
    local phase: Types.Phase = LocalRoundInfo.Phase() :: Types.Phase

    if status ~= "Alive" then
        roundInfo.Role.Text = "Spectating"
    elseif role ~= Defaults.Role then
        roundInfo.Role.Text = role:GetFormattedName()
    else
        roundInfo.Role.Text = phase
    end
end

participant.Status:Connect(setRoleText, true)
participant.Role:Connect(setRoleText, true)
LocalRoundInfo.Phase:Connect(setRoleText, true)

return table.freeze(module)