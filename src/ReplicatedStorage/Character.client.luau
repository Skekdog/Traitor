local ReplicatedStorage = game:GetService("ReplicatedStorage")
local JumpPower = require(script.Parent.JumpPower)
local LocalCharacter = require(script.Parent.LocalCharacter)
local WalkSpeed = require(script.Parent.WalkSpeed)

local clientServer = ReplicatedStorage:WaitForChild("ClientServer")

LocalCharacter.HumanoidAdded:Connect(function(hum)
    WalkSpeed.Reset()
    JumpPower.Reset()

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

    local char = hum.Parent
    assert(char, "Humanoid has no Character")

    local root = char:WaitForChild("HumanoidRootPart")
    assert(root:IsA("BasePart"), "HumanoidRootPart is not a Part")

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

    local neck = char:WaitForChild("Head"):WaitForChild("Neck")
    assert(neck:IsA("Motor6D"), "Neck is not a Motor6D")

    local camera = workspace.CurrentCamera

    local death = root:FindFirstChild("Died")
    if death then
        death:Destroy()
    else
        local con
        con = root.ChildAdded:Connect(function(child)
            if child.Name == "Died" then
                con:Disconnect()
                child:Destroy()
            end
        end)
    end

    local y = camera.CFrame:ToOrientation()
    while neck:IsDescendantOf(char) do
        task.wait(1 / 20)

        if not neck then
            break
        end

        local newY = camera.CFrame:ToOrientation()
        if newY == y then
            continue
        end

        y = newY
        clientServer.RotateHead:FireServer(y)
    end
end)