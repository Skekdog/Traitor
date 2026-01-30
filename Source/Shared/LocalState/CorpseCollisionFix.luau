local CollectionService = game:GetService("CollectionService")

task.spawn(function()
    while true do
        for _, corpse in CollectionService:GetTagged("Corpse") do
            for _, part in corpse:GetChildren() do
                if part:IsA("BasePart") then
                    part.CanCollide = part.Name ~= "HumanoidRootPart"
                end
            end
        end
        task.wait()
    end
end)

return nil