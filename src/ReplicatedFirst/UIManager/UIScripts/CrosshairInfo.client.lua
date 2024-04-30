local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UIManager = require(script.Parent.Parent)
--this script could do with a clean up

--To keep these ordered, they are regular tables, not dictionaries
local healthDefs = { --These are percentages of MaxHealth
	{100, "Healthy"},
	{80, "Hurt"},
	{60, "Wounded"},
	{40, "Badly Wounded"},
	{20, "Near Death"},
}

local karmaDefs = { --These are absolute karma values
	{1000, "Reputable"},
	{900, "Crude"},
	{800, "Trigger-Happy"},
	{700, "Dangerous"},
	{600, "Liability"},
}

local mouse = Players.LocalPlayer:GetMouse()
local ui = UIManager.WaitForUI("CrosshairInfo").UI

game:GetService("RunService").Heartbeat:Connect(function() --cant do getpropertychangedsignal
	local show = false
	if mouse.Target then
		local char = mouse.Target.Parent
		if char then
			local plr = Players:GetPlayerFromCharacter(char)
			if plr then
				local hum = char:FindFirstChild("Humanoid")
				if hum then
					local health = hum.Health
					if health > 0 then --finally
						local round = ReplicatedStorage.RoundHandler.GetPartialParticipants:InvokeServer()
						ui:FindFirstChild("Name").Text = plr.Name

						health = health/hum.MaxHealth*100
						local healthText = "Near Death"
						for i, v in healthDefs do
							if v[1] < health then
								healthText = healthDefs[i-1][2] or "Near Death"
								break
							end
						end

						ui.Health.Text = healthText
						ui.Health.TextColor3 = Color3.new(1, 0, 0):Lerp(Color3.new(1, 1, 1), health/100)

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
						
						if not table.find({"Starting", "Waiting"}, round.RoundInfo.RoundPhase) then
							local role = round.PlayerRoles[plr.Name]
							if role == "__!!Unknown" then role = "" else ui.Role.TextColor3 = round.RoundInfo.Gamemode.Roles[role].Colour end
							ui.Role.Text = role
						end
						
						ui.Mark.Text = plr:GetAttribute("Mark") or nil
						ui.Mark.TextColor3 = plr:GetAttribute("MarkColour") or Color3.new(0, 0, 0)
						
						show = true
					end
				end
			end
		end
	end
	ui.Visible = show
end)