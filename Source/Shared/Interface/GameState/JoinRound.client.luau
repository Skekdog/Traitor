local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UIManager = require(ReplicatedStorage.Shared.Interface.UILib.UIManager)
local ScreenMessage = require(ReplicatedStorage.Shared.Interface.Util.ScreenMessage)
local LocalRoundInfo = require(ReplicatedStorage.Shared.LocalState.LocalRoundInfo)
local Types = require(ReplicatedStorage.Shared.RoundRule.Types)

local this = UIManager.WaitForUI("JoinRound") :: UIManager.UI & {Object: typeof(UIManager.UnregisteredUIs.JoinRound)}

local validPhases: {Types.RoundPhase} = {"Waiting", "Preparing"}
local wasJoinClicked = false

local function shouldMakeVisible(): boolean
	local status = LocalRoundInfo.GetPlayerStatus()
	return not wasJoinClicked and table.find(validPhases, LocalRoundInfo.RoundPhase()) ~= nil and status == "Spectating"
end

this.Object.MouseButton1Click:Connect(function()
	wasJoinClicked = true
	this:ToggleVisible(false)
	local success = ReplicatedStorage.Remotes.ClientServer.JoinRound:InvokeServer()
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