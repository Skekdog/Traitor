local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local IS_SERVER = RunService:IsServer()

return function(door: BasePart, initialCFrame: CFrame, open: boolean, angleObject: NumberValue)
    local hingeCFrame = initialCFrame * CFrame.new(door.Size.X / -2, 0, 0)
    local offset = hingeCFrame:Inverse() * initialCFrame

    local targetAngle = if open then 90 else if IS_SERVER then -90 else 0
    if IS_SERVER then
        door.CFrame = hingeCFrame * CFrame.Angles(0, math.rad(targetAngle), 0) * offset
        return
    end

    TweenService:Create(angleObject, TweenInfo.new(1, Enum.EasingStyle.Linear), {Value = targetAngle}):Play()
    RunService.PreSimulation:Connect(function()
        door.CFrame = hingeCFrame * CFrame.Angles(0, math.rad(angleObject.Value), 0) * offset
    end)
end
