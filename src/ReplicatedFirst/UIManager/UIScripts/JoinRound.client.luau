local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalRoundInfo = require(ReplicatedFirst.LocalRoundInfo)
local API = require(ReplicatedFirst.API)
local UIManager = require(ReplicatedFirst.UIManager)
local roundInfo = UIManager.WaitForUI("RoundInfo").Object :: typeof(UIManager.UnregisteredUIs.RoundInfo)
local this = UIManager.WaitForUI("JoinRound") :: UIManager.UI & {Object: typeof(UIManager.UnregisteredUIs.JoinRound)}

this.Object.MouseButton1Click:Connect(function()
	this:ToggleVisible(false)
	local success = ReplicatedStorage.RoundHandler.JoinRound:InvokeServer()
	if not success then
		this:ToggleVisible(table.find({"Waiting", "Preparing"}, LocalRoundInfo.GetRoundPhase()) ~= nil)
		API.ScreenMessage("Error", "Failed to join round.")
		return
	end
	this:ToggleVisible(false)
	roundInfo.TopBar.Role.Text = "PREPARING"
	roundInfo.TopBar.Role.TextColor3 = Color3.new(1, 1, 1)
end)