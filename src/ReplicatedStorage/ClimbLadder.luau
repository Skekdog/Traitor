local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local module = {}
module.SnapCooldown = 0

local CLIMB_SPEED = 12
local MIN_LADDER_HEIGHT = 2.5

local thread: thread?
local jumpRequestCon: RBXScriptConnection?

local function setStates(hum: Humanoid, enabled: boolean): ()
    hum:SetStateEnabled(Enum.HumanoidStateType.Freefall, enabled)
    hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, enabled)
    hum:SetStateEnabled(Enum.HumanoidStateType.Climbing, not enabled)
    hum:ChangeState(if enabled then Enum.HumanoidStateType.Freefall else Enum.HumanoidStateType.Climbing)
    hum.PlatformStand = not enabled
    hum.AutoRotate = enabled
end

function module.Climb(ladder: BasePart): ()
    module.StopClimbing()

    local char = Players.LocalPlayer.Character
    if not char then
        return
    end

    local root = char.PrimaryPart
    if not root then
        return
    end

    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then
        return
    end
    setStates(hum, false)

    local alignPos = (root:FindFirstChild("LadderPositionAlignment") :: AlignPosition?) or Instance.new("AlignPosition")
    local ladderAttachment = (ladder:FindFirstChild("LadderAttachment") :: Attachment?) or Instance.new("Attachment")

    if not ladderAttachment.Parent then
        ladderAttachment.Name = "LadderAttachment"
        ladderAttachment.Parent = ladder
    end

    if not alignPos.Parent then
        alignPos.RigidityEnabled = true
        alignPos.Attachment0 = root:FindFirstChild("RootAttachment") :: Attachment?

        alignPos.Name = "LadderPositionAlignment"
        alignPos.Parent = root
    end

    jumpRequestCon = UserInputService.JumpRequest:Connect(function()
        module.StopClimbing()
    end)

    local ladderHeight = ladder.Size.Y / 2
    ladderAttachment.Position = Vector3.new(0, math.clamp(ladder.CFrame:PointToObjectSpace(root.Position).Y, -ladderHeight + MIN_LADDER_HEIGHT, ladderHeight), 0)

    char:PivotTo(CFrame.new(char:GetPivot().Position))

    alignPos.Attachment1 = ladderAttachment
    alignPos.Enabled = true

    local PlayerModule = (require)(Players.LocalPlayer.PlayerScripts:WaitForChild("PlayerModule"))
    local ControlModule = PlayerModule:GetControls()
    thread = coroutine.create(function()
        while true do
            local dt = RunService.PreSimulation:Wait()

            if not alignPos.Enabled then
                break
            end

            local z = ControlModule:GetMoveVector().Z
            if z == 0 then
                continue
            end

            local lastY = ladderAttachment.Position.Y
            ladderAttachment.Position = Vector3.new(0, math.clamp(lastY + (dt * if z < 0 then CLIMB_SPEED else -CLIMB_SPEED), -ladderHeight + MIN_LADDER_HEIGHT, ladderHeight + MIN_LADDER_HEIGHT), 0)

            if ladderAttachment.Position.Y >= ladderHeight + MIN_LADDER_HEIGHT or ladderAttachment.Position.Y <= -ladderHeight + MIN_LADDER_HEIGHT then
                task.defer(module.StopClimbing) -- We can't stop the current thread because its the current thread, so defer it to stop
            end
        end
    end)
    assert(thread)

    coroutine.resume(thread)
end

function module.StopClimbing(): ()
    if jumpRequestCon then
        jumpRequestCon:Disconnect()
    end

    if thread then
        coroutine.close(thread)
    end

    local char = Players.LocalPlayer.Character
    if not char then
        return
    end

    local root = char.PrimaryPart
    if not root then
        return
    end

    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then
        return
    end
    setStates(hum, true)

    if hum:GetState() == Enum.HumanoidStateType.Swimming then
        hum:ChangeState(Enum.HumanoidStateType.GettingUp)
    end

    local alignPos = root:FindFirstChild("LadderPositionAlignment") :: AlignPosition?
    if alignPos and alignPos.Enabled then
        module.SnapCooldown = os.clock() + 3
        alignPos.Enabled = false
    end
end

return module