local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local JumpPower = require(script.Parent.JumpPower)
local WalkSpeed = require(script.Parent.WalkSpeed)

local clientServer = ReplicatedStorage:WaitForChild("ClientServer")

Players.LocalPlayer.CharacterAdded:Connect(function(char: Model)
    WalkSpeed.Reset()
    JumpPower.Reset()
    
    local hum = char:WaitForChild("Humanoid")
    assert(hum:IsA("Humanoid"), "Humanoid is not a Humanoid")

    hum:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
    hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
    hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
    hum:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)
    hum:SetStateEnabled(Enum.HumanoidStateType.Flying, false)
    hum:SetStateEnabled(Enum.HumanoidStateType.PlatformStanding, false)
    hum:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
    hum:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
    hum:SetStateEnabled(Enum.HumanoidStateType.RunningNoPhysics, false)
    hum:SetStateEnabled(Enum.HumanoidStateType.StrafingNoPhysics, false)

    local root = char:WaitForChild("HumanoidRootPart")
    assert(root:IsA("BasePart"))

    local death = root:WaitForChild("Died", 1)
    
    if death then
        death:Destroy()
    end

    local startHeight = math.huge
    hum.StateChanged:Connect(function(_, state)
        if state == Enum.HumanoidStateType.Freefall then
            startHeight = root.Position.Y
        elseif state == Enum.HumanoidStateType.Landed then
            local distance = startHeight - root.Position.Y
            if distance > 15 then
                clientServer.Fell:FireServer(startHeight - root.Position.Y)
            end
            startHeight = math.huge
        elseif state == Enum.HumanoidStateType.Climbing then
            startHeight = math.huge
        end
    end)

    local camera = workspace.CurrentCamera
    while char.Parent do
        task.wait(1 / 20)
        local y = camera.CFrame:ToOrientation()
        local neck = char:FindFirstChild("Neck", true) :: Motor6D?
        if not neck then
            continue
        end
        clientServer.RotateHead:FireServer(y)
    end
end)