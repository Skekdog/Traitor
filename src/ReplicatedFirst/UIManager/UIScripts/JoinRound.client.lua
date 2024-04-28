local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TCS = game:GetService("TextChatService")

local plr = Players.LocalPlayer
local UI = require(game:GetService("ReplicatedFirst").UIManager)
local roundInfo = UI.WaitForUI("RoundInfo").UI
local this = UI.WaitForUI("JoinRound")

local system = TCS:WaitForChild("TextChannels"):WaitForChild("RBXSystem")

local clientStorage = game:WaitForChild("ClientStorage")
local scriptCons = clientStorage:WaitForChild("ScriptConnections")

this.UI.MouseButton1Click:Connect(function()
	ReplicatedStorage.ClientServer.JoinRound:FireServer("Main")
	plr:SetAttribute("InRound",true)
	this:ToggleVisible(false)
	roundInfo.Frame.Role.Text = "PREPARING"
	roundInfo.Frame.Role.TextColor3 = Color3.new(1,1,1)
	
	scriptCons.JoinRoundEvent:Fire("Main")
	for _,v in plr:WaitForChild("Inventory"):GetChildren() do
		scriptCons.RemoteEquipEvent:Fire(false,v,nil,false)
	end
	
	local karma = ReplicatedStorage.ClientServer.GetKarma:InvokeServer(plr)
	if karma then
		karma = math.round(karma)
		system:DisplaySystemMessage(`<font color='#2294ff'>Your karma is {karma}. You will do {karma/(10)}% damage this round.</font>`)
	else
		system:DisplaySystemMessage("<font color='#fcbf3a'>Failed to load karma locally. You will still have a damage penalty if applicable.</font>")
	end
	
	plr.PlayerGui:WaitForChild("HUD"):WaitForChild("Credits").Visible = true
	delay(5,function()
		plr.PlayerGui:WaitForChild("HUD"):WaitForChild("Credits").Visible = false
	end)
end)