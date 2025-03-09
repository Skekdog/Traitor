workspace.Corpses.ChildAdded:Connect(function(child)
    while child.Parent do
        for _, v in child:GetDescendants() do
            if v:IsA("BasePart") and v.Name ~= "HumanoidRootPart" then
                v.CanCollide = true
            end
        end
        task.wait()
    end
end)

return nil