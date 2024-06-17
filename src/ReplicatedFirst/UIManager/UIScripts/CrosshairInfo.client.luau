local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local UIManager = require(script.Parent.Parent)
local ControlManager = require(script.Parent.Parent.Parent.ControlManager)
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
local playerInfo = ui.PlayerInfo

local function showPlayerInfo(char: Model)
	local plr = Players:GetPlayerFromCharacter(char)
	if not plr then return end

	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum then return end

	local health = hum.Health
	if health <= 0 then return end

	local participant = LocalRoundInfo.GetParticipantInfo(plr.Name)
	if not participant then return end

	local role = LocalRoundInfo.GetRole(participant.Role)
	playerInfo:FindFirstChild("Name").Text = plr.Name

	local healthPercent = health / hum.MaxHealth * 100
	local healthText = ""

	for i, v in healthDefs do
		if i <= health then
			healthText = v
			break
		end
	end

	playerInfo.Health.Text = healthText
	playerInfo.Health.TextColor3 = Color3.new(1, 0, 0):Lerp(Color3.new(1, 1, 1), healthPercent/100)

	local karma = 1000
	local karmaText = ""
	for i, v in karmaDefs do
		if i <= karma then
			karmaText = v
			break
		end
	end

	playerInfo.Karma.Text = karmaText	
	playerInfo.Karma.TextColor3 = Color3.new(1, 0, 0):Lerp(Color3.new(1, 1, 1), karma / 1000)

	if role then
		playerInfo.Role.TextColor3 = role.Colour
		playerInfo.Role.Text = role.Name
	else
		playerInfo.Role.Text = ""
	end

	playerInfo.Mark.Text = plr:GetAttribute("Mark") or ""
	playerInfo.Mark.TextColor3 = plr:GetAttribute("MarkColour") or Color3.new(0, 0, 0)

	playerInfo.Visible = true
	return true
end

local corpseHint = ui.SearchCorpseHint
local function showCorpseHint(char: Model)
	local plr = Players.LocalPlayer

	if plr:DistanceFromCharacter(char:GetPivot().Position) > 10 then
		return
	end

	local key = ControlManager.GetFirstKeyCode("Interact")

	if char.Name == "__Unidentified" then
		corpseHint.Text = `<font color='#ffff00'>Unidentified</font> Body\nPress {key} to Search`
	else
		local info = LocalRoundInfo.GetParticipantInfo(char.Name)
		assert(info)
		corpseHint.Text = `{info.FormattedName}'s Body\nPress {key} to Search`
	end
	corpseHint.Visible = true
end

local lastInstance: BasePart
game:GetService("RunService").Heartbeat:Connect(function() --cant do getpropertychangedsignal
	if mouse.Target == lastInstance then
		return
	end

	playerInfo.Visible = false
	corpseHint.Visible = false
	if not mouse.Target then
		return
	end

	lastInstance = mouse.Target
	
	local char = mouse.Target.Parent
	if not char or char.Parent ~= workspace or not char:IsA("Model") then
		return
	end

	if char:GetAttribute("IsCorpse") then
		showCorpseHint(char)
	else
		showPlayerInfo(char)
	end
end)