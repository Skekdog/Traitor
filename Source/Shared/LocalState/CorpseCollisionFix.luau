local CollectionService = game:GetService("CollectionService")

local function fix(corpse: Instance)
    for _, part in corpse:GetChildren() do
        if not part:IsA("BasePart") or part:FindFirstAncestorWhichIsA("Accessory") or part:FindFirstAncestor("Item") or part.Name == "Item" then
            continue
        end
        part.CanCollide = part.Name ~= "HumanoidRootPart"
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