return function(cframe: CFrame, children: {Instance}?, canCollide: boolean?, canTouch: boolean?, canQuery: boolean?): Part
    local part = Instance.new("Part")

    part.CanCollide = canCollide or false
    part.CanTouch = canTouch or false
    part.CanQuery = canQuery or false

    part.CFrame = cframe
    part.Anchored = true
    part.Massless = true
    part.Transparency = 1

    if children then
        for _, v in children do
            v.Parent = part
        end
    end

    return part
end