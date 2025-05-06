task.spawn(function()
    while true do
        for _, corpse in workspace.Corpses:GetChildren() do
            for _, part in corpse:GetDescendants() do
                if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                    part.CanCollide = true
                end
            end
        end
        task.wait()
    end
end)

return nil