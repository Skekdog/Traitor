local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local IS_SERVER = RunService:IsServer()

return function(door: BasePart): ()
    if door:GetAttribute("Opening") then
        return
    end

    door:SetAttribute("Opening", true)

    local angle = door:FindFirstChild("DoorAngle") :: NumberValue or Instance.new("NumberValue")
    if not angle.Parent then
        angle.Name = "DoorAngle"
        angle.Parent = door
    end

    assert(angle:IsA("NumberValue"), "DoorAngle must be a NumberValue")

    local open = not door:GetAttribute("Open")
    door:SetAttribute("Open", open)

    local initialCFrame = door.CFrame

    local hingeCFrame = initialCFrame * CFrame.new(door.Size.X / -2, 0, 0)
    local offset = hingeCFrame:Inverse() * initialCFrame

    local sounds = {}
    for _, v in door:GetChildren() do
        if v:IsA("Sound") and v.Name == if open then "OpenSound" else "CloseSound" then
            table.insert(sounds, v)
        end
    end
    sounds[math.random(1, #sounds)]:Play()

    task.delay(1, door.SetAttribute, door, "Opening", false)

    local targetAngle = if open then 90 else if IS_SERVER then -90 else 0
    if IS_SERVER then
        door.CFrame = hingeCFrame * CFrame.Angles(0, math.rad(targetAngle), 0) * offset
        return
    end

    TweenService:Create(angle, TweenInfo.new(1, Enum.EasingStyle.Linear), {Value = targetAngle}):Play()
    RunService.PreSimulation:Connect(function()
        door.CFrame = hingeCFrame * CFrame.Angles(0, math.rad(angle.Value), 0) * offset
    end)
end