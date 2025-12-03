return function(gun: BasePart): ()
    local attachment = gun:FindFirstChild("MuzzleFlash")
    if not attachment or not attachment:IsA("Attachment") then
        return
    end

    local a0 = gun:FindFirstChild("MuzzleFlash0")
    local a1 = gun:FindFirstChild("MuzzleFlash1")

    if not a0 then
        local a = Instance.fromExisting(attachment)
        a.CFrame *= CFrame.new(0.375, 0.375, 0) * CFrame.Angles(math.rad(0), 0, math.rad(45))
        a.Name = "MuzzleFlash0"
        a.Parent = gun
        a0 = a
    end
    if not a1 then
        local a = Instance.fromExisting(attachment)
        a.CFrame *= CFrame.new(-0.375, -0.375, 0) * CFrame.Angles(math.rad(0), 0, math.rad(45))
        a.Name = "MuzzleFlash1"
        a.Parent = gun
        a1 = a
    end

    assert(a0 and a1 and a0:IsA("Attachment") and a1:IsA("Attachment"))

    local beam = Instance.new("Beam")
    beam.Attachment0 = a0
    beam.Attachment1 = a1
    beam.Transparency = NumberSequence.new(0.25)
    beam.LightEmission = 1
    beam.Segments = 1
    beam.TextureSpeed = math.random(-1, 1)
    beam.Texture = "rbxassetid://872910628"
    beam.Color = ColorSequence.new(Color3.fromRGB(214, 171, 0), Color3.fromRGB(255, 234, 111))
    beam.Name = "MuzzleFlashBeam"
    beam.Parent = gun

    task.delay(0.1, beam.Destroy, beam)
end