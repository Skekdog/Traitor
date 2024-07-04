local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalRoundInfo = require(ReplicatedFirst.LocalRoundInfo)
local API = require(ReplicatedFirst.API)
local UIManager = require(ReplicatedFirst.UIManager)
local this = UIManager.WaitForUI("JoinRound") :: UIManager.UI & {Object: typeof(UIManager.UnregisteredUIs.JoinRound)}

local validPhases = {"Waiting", "Preparing", "Destroy"}
local isInRound = false
this.Object.MouseButton1Click:Connect(function()
	isInRound = true
	this:ToggleVisible(false)
	local success = ReplicatedStorage.RoundHandler.JoinRound:InvokeServer()
	if not success then
		isInRound = false
		this:ToggleVisible(table.find(validPhases, LocalRoundInfo.GetRoundPhase()) ~= nil)
		API.ScreenMessage("Error", "Failed to join round.")
		return
	end
end)

LocalRoundInfo.Listen("RoundPhase", function(phase)
	isInRound = LocalRoundInfo.GetOwnParticipant() ~= nil
	this:ToggleVisible(not isInRound and table.find(validPhases, phase :: string) ~= nil)
end)

LocalRoundInfo.Listen("UpdateOwnParticipant", function(p)
	isInRound = p ~= nil
	this:ToggleVisible(not isInRound and table.find(validPhases, LocalRoundInfo.GetRoundPhase()) ~= nil)
end)