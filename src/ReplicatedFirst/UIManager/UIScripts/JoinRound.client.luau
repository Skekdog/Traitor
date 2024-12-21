local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(script.Parent.Parent.Parent.RoundRule.Types)
local ScreenMessage = require(script.Parent.Parent.Parent.ScreenMessage)
local LocalRoundInfo = require(ReplicatedFirst.LocalRoundInfo)
local UIManager = require(ReplicatedFirst.UIManager)

local this = UIManager.WaitForUI("JoinRound") :: UIManager.UI & {Object: typeof(UIManager.UnregisteredUIs.JoinRound)}

--todo: hide button if in round

local validPhases: {Types.RoundPhase} = {"Waiting", "Preparing"}
this.Object.MouseButton1Click:Connect(function()
	this:ToggleVisible(false)
	local success = ReplicatedStorage:WaitForChild("RoundHandler").JoinRound:InvokeServer()
	if not success then
		this:ToggleVisible(table.find(validPhases, LocalRoundInfo.GetRoundPhase()) ~= nil)
		ScreenMessage("Error", "Failed to join round.")
		return
	end
end)

LocalRoundInfo.Listen("Phase", function()
	local phase = LocalRoundInfo.GetRoundPhase()
	this:ToggleVisible(table.find(validPhases, phase) ~= nil)
end)

if table.find(validPhases, LocalRoundInfo.GetRoundPhase()) then
	this:ToggleVisible(true)
end
