local ReplicatedFirst = game:GetService("ReplicatedFirst")
local TweenService = game:GetService("TweenService")
local plr = game:GetService("Players").LocalPlayer
local UIManager = require(ReplicatedFirst.UIManager)

local frame = (UIManager.WaitForUI("RoundInfo").Object :: typeof(ReplicatedFirst.UIManager.UnregisteredUIs.RoundInfo)).Frame
local health = frame.HealthBar

plr:GetPropertyChangedSignal("Character"):Connect(function()
	local char = plr.Character
	if char then
		local hum = char:WaitForChild("Humanoid") :: Humanoid
		health.Text = tostring(hum.Health)
		health.UIGradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.new(0.785, 0, 0)),
			ColorSequenceKeypoint.new(math.clamp(hum.Health/hum.MaxHealth, 0, 0.999), Color3.new(0.785, 0, 0)),
			ColorSequenceKeypoint.new(math.clamp((hum.Health/hum.MaxHealth)+0.001, 0.001, 1), Color3.new(0.2, 0, 0)),
			ColorSequenceKeypoint.new(1, Color3.new(0.2, 0, 0)),
		})
		hum:GetPropertyChangedSignal("Health"):Connect(function()
			health.Text = tostring(math.round(hum.Health))
			health.UIGradient.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.new(0.785, 0, 0)),
				ColorSequenceKeypoint.new(math.clamp(hum.Health/hum.MaxHealth, 0, 0.999), Color3.new(0.785, 0, 0)),
				ColorSequenceKeypoint.new(math.clamp((hum.Health/hum.MaxHealth)+0.001, 0.001, 1), Color3.new(0.2, 0, 0)),
				ColorSequenceKeypoint.new(1, Color3.new(0.2, 0, 0)),
			})
		end)
	end
end)