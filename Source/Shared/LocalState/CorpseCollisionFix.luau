local CollectionService = game:GetService("CollectionService")

local function fix(corpse: Instance)
    for _, part in corpse:GetChildren() do
        if part:IsA("BasePart") then
            part.CanCollide = part.Name ~= "HumanoidRootPart"
        end
    end
end

task.spawn(function()
    while true do
        for _, corpse in CollectionService:GetTagged("Corpse") do
            fix(corpse)
        end
        for _, corpse in CollectionService:GetTagged("Ragdoll") do
            fix(corpse)
        end
        task.wait()
    end
end)

return nil