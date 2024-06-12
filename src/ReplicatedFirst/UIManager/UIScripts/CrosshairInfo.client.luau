local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local UIManager = require(script.Parent.Parent)
local LocalRoundInfo = require(script.Parent.Parent.Parent.LocalRoundInfo)
--this script could do with a clean up

-- These are percentages of MaxHealth
local healthDefs = {
	[0] = "Near Death",
	[20] = "Badly Wounded",
	[40] = "Wounded",
	[60] = "Hurt",
	[80] = "Healthy",
}

local karmaDefs = {
	[500] = "Liability",
	[600] = "Dangerous",
	[700] = "Trigger-Happy",
	[800] = "Crude",
	[900] = "Reputable",
}

local mouse = Players.LocalPlayer:GetMouse()
local ui = UIManager.WaitForUI("CrosshairInfo").Object :: typeof(ReplicatedFirst.UIManager.UnregisteredUIs.CrosshairInfo)

game:GetService("RunService").Heartbeat:Connect(function() --cant do getpropertychangedsignal
	ui.Visible = false
	if not mouse.Target then return end
	
	local char = mouse.Target.Parent :: Model
	if not char then return end

	local plr = Players:GetPlayerFromCharacter(char)
	if not plr then return end

	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum then return end

	local health = hum.Health
	if health <= 0 then return end

	local participant = LocalRoundInfo.GetParticipantInfo(plr.Name)
	if not participant then return end

	local role = participant.Role
	ui:FindFirstChild("Name").Text = plr.Name

	local healthPercent = health / hum.MaxHealth * 100
	local healthText = ""

	for i, v in healthDefs do
		if i <= health then
			healthText = v
			break
		end
	end

	ui.Health.Text = healthText
	ui.Health.TextColor3 = Color3.new(1, 0, 0):Lerp(Color3.new(1, 1, 1), healthPercent/100)

	local karma = 1000
	local karmaText = ""
	for i, v in karmaDefs do
		if i <= karma then
			karmaText = v
			break
		end
	end

	ui.Karma.Text = karmaText	
	ui.Karma.TextColor3 = Color3.new(1, 0, 0):Lerp(Color3.new(1, 1, 1), karma / 1000)

	if role then
		ui.Role.TextColor3 = role.Colour
		ui.Role.Text = role.Name
	else
		ui.Role.Text = ""
	end

	ui.Mark.Text = plr:GetAttribute("Mark") or ""
	ui.Mark.TextColor3 = plr:GetAttribute("MarkColour") or Color3.new(0, 0, 0)

	ui.Visible = true
end)