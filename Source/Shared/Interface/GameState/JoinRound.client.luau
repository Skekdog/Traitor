local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalRoundInfo = require(ReplicatedStorage.LocalRoundInfo)
local Types = require(ReplicatedStorage.RoundRule.Types)
local ScreenMessage = require(ReplicatedStorage.ScreenMessage)
local UIManager = require(ReplicatedStorage.UIManager)

local this = UIManager.WaitForUI("JoinRound") :: UIManager.UI & {Object: typeof(UIManager.UnregisteredUIs.JoinRound)}

local validPhases: {Types.RoundPhase} = {"Waiting", "Preparing"}
local wasJoinClicked = false

local function shouldMakeVisible(): boolean
	local statusValue = LocalRoundInfo.PlayerStatuses()[Players.LocalPlayer.Name]
	local status = if statusValue then statusValue() else "Spectating"
	return not wasJoinClicked and table.find(validPhases, LocalRoundInfo.RoundPhase()) ~= nil and status == "Spectating"
end

this.Object.MouseButton1Click:Connect(function()
	wasJoinClicked = true
	this:ToggleVisible(false)
	local success = ReplicatedStorage.ClientServer.JoinRound:InvokeServer()
	wasJoinClicked = false
	if not success then
		this:ToggleVisible(shouldMakeVisible())
		ScreenMessage("Error", "Failed to join round.")
		return
	end
end)

LocalRoundInfo.RoundPhase:Connect(function()
	this:ToggleVisible(shouldMakeVisible())
end, true)

LocalRoundInfo.PlayerStatuses:Connect(function()
	this:ToggleVisible(shouldMakeVisible())
end, true)