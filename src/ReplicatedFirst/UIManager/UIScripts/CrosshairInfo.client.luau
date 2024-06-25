local Players = game:GetService("Players")
local UIManager = require(script.Parent.Parent)
local ControlManager = require(script.Parent.Parent.Parent.ControlManager)
local LocalRoundInfo = require(script.Parent.Parent.Parent.LocalRoundInfo)

local mouse = Players.LocalPlayer:GetMouse()
local ui = UIManager.WaitForUI("CrosshairInfo").Object :: typeof(UIManager.UnregisteredUIs.CrosshairInfo)
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

	if healthPercent >= 80 then
		healthText = "Healthy"
	elseif healthPercent >= 60 then
		healthText = "Hurt"
	elseif healthPercent >= 40 then
		healthText = "Wounded"
	elseif healthPercent >= 20 then
		healthText = "Badly Wounded"
	else
		healthText = "Near Death"
	end

	playerInfo.Health.Text = healthText
	playerInfo.Health.TextColor3 = Color3.new(1, 0, 0):Lerp(Color3.new(1, 1, 1), healthPercent/100)

	local karma = 1000
	local karmaText = ""
	if karma >= 900 then
		karmaText = "Reputable"
	elseif karma >= 800 then
		karmaText = "Crude"
	elseif karma >= 700 then
		karmaText = "Trigger-Happy"
	elseif karma >= 600 then
		karmaText = "Dangerous"
	elseif karma >= 500 then
		karmaText = "Liability"
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
		local info = LocalRoundInfo.GetParticipantInfo(char.Name) or LocalRoundInfo.GetOwnParticipant()
		assert(info)
		corpseHint.Text = `{info.FormattedName}'s Body\nPress {key} to Search`
	end
	corpseHint.Visible = true
end

game:GetService("RunService").Heartbeat:Connect(function()
	playerInfo.Visible = false
	corpseHint.Visible = false
	if not mouse.Target then
		return
	end
	
	local char = mouse.Target:FindFirstAncestorOfClass("Model")
	if not char or char.Parent ~= workspace then
		return
	end

	if char:GetAttribute("IsCorpse") then
		showCorpseHint(char)
	else
		showPlayerInfo(char)
	end
end)