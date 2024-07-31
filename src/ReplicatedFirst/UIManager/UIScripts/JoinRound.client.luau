local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ScreenMessage = require(script.Parent.Parent.Parent.ScreenMessage)
local LocalRoundInfo = require(ReplicatedFirst.LocalRoundInfo)
local UIManager = require(ReplicatedFirst.UIManager)

local this = UIManager.WaitForUI("JoinRound") :: UIManager.UI & {Object: typeof(UIManager.UnregisteredUIs.JoinRound)}

local validPhases = {"Waiting", "Preparing", "Destroy"}
local isInRound = false
this.Object.MouseButton1Click:Connect(function()
	isInRound = true
	this:ToggleVisible(false)
	local success = ReplicatedStorage:WaitForChild("RoundHandler").JoinRound:InvokeServer()
	if not success then
		isInRound = false
		this:ToggleVisible(table.find(validPhases, LocalRoundInfo.GetRoundPhase()) ~= nil)
		ScreenMessage("Error", "Failed to join round.")
		return
	end
end)

LocalRoundInfo.Listen("RoundPhase", function(phase)
	isInRound = LocalRoundInfo.GetOwnParticipant() ~= nil
	this:ToggleVisible(not isInRound and table.find(validPhases, phase) ~= nil)
end)

LocalRoundInfo.Listen("UpdateOwnParticipant", function(p)
	isInRound = p ~= nil
	this:ToggleVisible(not isInRound and table.find(validPhases, LocalRoundInfo.GetRoundPhase()) ~= nil)
end)

print(LocalRoundInfo.GetRoundPhase())
if table.find(validPhases, LocalRoundInfo.GetRoundPhase()) then
	this:ToggleVisible(true)
end
