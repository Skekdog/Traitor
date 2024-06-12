local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UIManager = require(script.Parent.UIManager)

local roundInfo = UIManager.WaitForUI("RoundInfo").Object :: typeof(script.Parent.UIManager.UnregisteredUIs.RoundInfo)
Players.LocalPlayer.CharacterAdded:Connect(function(char)
    script.Parent.ClientStorage:SetAttribute("IsSpectating", false)

    local hum = char:WaitForChild("Humanoid") :: Humanoid
    hum.Died:Once(function()
        script.Parent.ClientStorage:SetAttribute("IsSpectating", true)
    end)

    roundInfo.Frame.HealthBar.Visible = true

    local activeTween: Tween
    hum:GetPropertyChangedSignal("Health"):Connect(function()
        roundInfo.Frame.HealthBar.HealthLabel.Text = tostring(math.round(hum.Health))
        if activeTween then
            activeTween:Cancel()
        end
        activeTween = TweenService:Create(roundInfo.Frame.HealthBar.Background, TweenInfo.new(0.1), {Size = UDim2.new(hum.Health/hum.MaxHealth, 0, 1, 0)})
        activeTween:Play()
    end)
end)

Players.LocalPlayer.CharacterRemoving:Connect(function()
    roundInfo.Frame.HealthBar.Visible = false
end)