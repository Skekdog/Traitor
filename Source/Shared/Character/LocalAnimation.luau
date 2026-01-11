local LocalCharacter = require(script.Parent.LocalCharacter)

local module = {}

local function tryGetAnimator(): Animator?
    local hum = LocalCharacter.Humanoid()
    if not hum then
        return nil
    end

    return hum:FindFirstChildOfClass("Animator")
end

function module.TryPlayAnimation(content: Content, name: string): AnimationTrack?
	local animator = tryGetAnimator()
    if not animator then
        return nil
    end

    local animation = Instance.new("Animation")
    animation.AnimationId = content.Uri or ""

    local track = animator:LoadAnimation(animation)
    track.Name = name

    track:Play()

    return track
end

function module.TryStopAnimation(name: string): ()
	local animator = tryGetAnimator()
    if not animator then
        return
    end

    for _, v in animator:GetPlayingAnimationTracks() do
        if v.Name == name and v.IsPlaying then
            v:Stop()
        end
    end
end


return module