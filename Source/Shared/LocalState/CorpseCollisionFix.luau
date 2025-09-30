local CollectionService = game:GetService("CollectionService")
local noCollisionLimbs = {"LeftUpperArm", "RightUpperArm", "LowerTorso", "LeftUpperLeg", "RightUpperLeg", "HumanoidRootPart"}

task.spawn(function()
    while true do
        for _, corpse in CollectionService:GetTagged("Corpse") do
            for _, part in corpse:GetChildren() do
                if part:IsA("BasePart") then
                    part.CanCollide = not table.find(noCollisionLimbs, part.Name)
                end
            end
        end
        task.wait()
    end
end)

return nil