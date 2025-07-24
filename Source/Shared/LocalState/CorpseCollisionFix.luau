local noCollisionLimbs = {"LeftUpperArm", "RightUpperArm", "LowerTorso", "LeftUpperLeg", "RightUpperLeg"}

task.spawn(function()
    while true do
        for _, corpse in workspace.Corpses:GetChildren() do
            for _, part in corpse:GetChildren() do
                if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                    part.CanCollide = not table.find(noCollisionLimbs, part.Name)
                end
            end
        end
        task.wait()
    end
end)

return nil