return function(name: string, value: boolean): ()
	if value then
        return
    end

    for _, v in workspace.Projectiles:GetChildren() do
        if v.Name == "GlassFragment" then
            v:Destroy()
        end
    end
end
