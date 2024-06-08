local Players = game:GetService("Players")
Players.LocalPlayer.CharacterAdded:Connect(function(char)
    script.Parent.ClientStorage:SetAttribute("IsSpectating", false)

    local hum = char:WaitForChild("Humanoid") :: Humanoid
    hum.Died:Once(function()
        script.Parent.ClientStorage:SetAttribute("IsSpectating", true)
    end)
end)