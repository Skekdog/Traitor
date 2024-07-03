local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalRoundInfo = require(ReplicatedFirst.LocalRoundInfo)
local API = require(ReplicatedFirst.API)
local UIManager = require(ReplicatedFirst.UIManager)
local this = UIManager.WaitForUI("JoinRound") :: UIManager.UI & {Object: typeof(UIManager.UnregisteredUIs.JoinRound)}

this.Object.MouseButton1Click:Connect(function()
	this:ToggleVisible(false)
	LocalRoundInfo.SetInRound(true)
	local success = ReplicatedStorage.RoundHandler.JoinRound:InvokeServer()
	if not success then
		LocalRoundInfo.SetInRound(false)
		this:ToggleVisible(table.find({"Waiting", "Preparing"}, LocalRoundInfo.GetRoundPhase()) ~= nil)
		API.ScreenMessage("Error", "Failed to join round.")
		return
	end
end)

LocalRoundInfo.Listen("RoundPhase", function(phase)
	this:ToggleVisible(not LocalRoundInfo.IsInRound() and (phase == "Waiting" or phase == "Preparing" or phase == "Destroy"))
end)
