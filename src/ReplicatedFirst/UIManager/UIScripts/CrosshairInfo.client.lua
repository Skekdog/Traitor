local Players = game:GetService("Players")
local UIManager = require(script.Parent.Parent)
local LocalRoundInfo = require(script.Parent.Parent.Parent.LocalRoundInfo)
--this script could do with a clean up

--To keep these ordered, they are regular tables, not dictionaries
local healthDefs = { --These are percentages of MaxHealth
	{100 :: any, "Healthy"},
	{80 :: any, "Hurt"},
	{60 :: any, "Wounded"},
	{40 :: any, "Badly Wounded"},
	{20 :: any, "Near Death"},
}

local karmaDefs = { --These are absolute karma values
	{1000 :: any, "Reputable"},
	{900 :: any, "Crude"},
	{800 :: any, "Trigger-Happy"},
	{700 :: any, "Dangerous"},
	{600 :: any, "Liability"},
}

local mouse = Players.LocalPlayer:GetMouse()
local ui = UIManager.WaitForUI("CrosshairInfo").UI :: any

game:GetService("RunService").Heartbeat:Connect(function() --cant do getpropertychangedsignal
	ui.Visible = false
	if not mouse.Target then return end
	
	local char = mouse.Target.Parent
	if not char then return end

	local plr = Players:GetPlayerFromCharacter(char :: any)
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
	local healthText = "Near Death"
	for i, v in healthDefs do
		if v[1] < health then
			healthText = healthDefs[i-1][2] or "Near Death"
			break
		end
	end

	ui.Health.Text = healthText
	ui.Health.TextColor3 = Color3.new(1, 0, 0):Lerp(Color3.new(1, 1, 1), healthPercent/100)

	local karma = 1000
	local karmaText = "Liability"
	for i, v in karmaDefs do
		if v[1] < karma then
			karmaText = karmaDefs[i-1][2] or "Liability"
			break
		end
	end

	ui.Karma.Text = karmaText	
	ui.Karma.TextColor3 = Color3.new(1, 0, 0):Lerp(Color3.new(1, 1, 1), karma/1000)

	if not table.find({"Starting", "Waiting"}, LocalRoundInfo.GetRoundPhase()) then
		if not role then
			ui.Role.Text = ""
		else
			ui.Role.TextColor3 = role.Colour
			ui.Role.Text = role.Name
		end
	end

	ui.Mark.Text = plr:GetAttribute("Mark") or ""
	ui.Mark.TextColor3 = plr:GetAttribute("MarkColour") or Color3.new(0, 0, 0)

	ui.Visible = true
end)