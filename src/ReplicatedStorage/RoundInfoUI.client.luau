local Players = game:GetService("Players")
local LocalRoundInfo = require(script.Parent.LocalRoundInfo)
local ToRoundTime = require(script.Parent.ToRoundTime)
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
