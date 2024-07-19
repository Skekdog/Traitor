return function(plr: Player, id: number, name: string): Model?
    local char = plr.Character
    if not char then
        return
    end

    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then
        return
    end

    local animator = hum:FindFirstChildOfClass("Animator")
    if not animator then
        return
    end

    local animation = Instance.new("Animation")
    animation.AnimationId = "rbxassetid://"..id

    local track = animator:LoadAnimation(animation)
    track.Name = name

    track:Play()
    return char
end