local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local API = require(ReplicatedFirst.API)
local UIManager = require(ReplicatedFirst.UIManager)
local roundInfo = UIManager.WaitForUI("RoundInfo").Object :: typeof(UIManager.UnregisteredUIs.RoundInfo)
local this = UIManager.WaitForUI("JoinRound") :: UIManager.UI & {Object: typeof(UIManager.UnregisteredUIs.JoinRound)}

this.Object.MouseButton1Click:Connect(function()
	local success = ReplicatedStorage.RoundHandler.JoinRound:InvokeServer()
	if not success then
		API.ScreenMessage("Error", "Failed to join round.")
		return
	end
	this:ToggleVisible(false)
	roundInfo.TopBar.Role.Text = "PREPARING"
	roundInfo.TopBar.Role.TextColor3 = Color3.new(1, 1, 1)
end)