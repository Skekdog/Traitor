local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ControlManager = require(script.Parent.ControlManager)
local UIManager = require(script.Parent.UIManager)

local roundInfo = UIManager.WaitForUI("RoundInfo").Object :: typeof(script.Parent.UIManager.UnregisteredUIs.RoundInfo)

local activeTween: Tween
local function setHealth(hum: Humanoid)
    roundInfo.Frame.HealthBar.HealthLabel.Text = tostring(math.round(hum.Health))
    if activeTween then
        activeTween:Cancel()
    end
    activeTween = TweenService:Create(roundInfo.Frame.HealthBar.Background, TweenInfo.new(0.1), {Size = UDim2.new(hum.Health/hum.MaxHealth, 0, 1, 0)})
    activeTween:Play()
end

Players.LocalPlayer.CharacterAdded:Connect(function(char)
    script.Parent.ClientStorage:SetAttribute("IsSpectating", false)

    local hum = char:WaitForChild("Humanoid") :: Humanoid
    hum.Died:Once(function()
        script.Parent.ClientStorage:SetAttribute("IsSpectating", true)
        ControlManager.Unregister("Primary Fire")
		ControlManager.Unregister("Drop")
		ControlManager.Unregister("Reload Weapon")
    end)

    roundInfo.Frame.HealthBar.Visible = true

    setHealth(hum)
    hum:GetPropertyChangedSignal("Health"):Connect(function()
        setHealth(hum)
    end)
end)

Players.LocalPlayer.CharacterRemoving:Connect(function()
    roundInfo.Frame.HealthBar.Visible = false
end)