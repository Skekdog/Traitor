local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local plr = Players.LocalPlayer
local API = require(ReplicatedFirst.API)
local UI = require(ReplicatedFirst.UIManager)
local roundInfo: typeof(ReplicatedFirst.UIManager.UnregisteredUIs.HUD.RoundInfo) = UI.WaitForUI("RoundInfo").UI
local this = UI.WaitForUI("JoinRound")

this.UI.MouseButton1Click:Connect(function()
	local success = ReplicatedStorage.RoundHandler.JoinRound:InvokeServer()
	if not success then
		API.ScreenMessage("Error", "Failed to join round.")
		return
	end
	plr:SetAttribute("IsSpectating", false)
	this:ToggleVisible(false)
	roundInfo.Frame.Role.Text = "PREPARING"
	roundInfo.Frame.Role.TextColor3 = Color3.new(1, 1, 1)
	
	for _, v in plr:WaitForChild("Inventory"):GetChildren() do
		ReplicatedFirst.ClientStorage.ScriptConnections.RemoteEquipEvent:Fire(false, v, nil, false)
	end
end)