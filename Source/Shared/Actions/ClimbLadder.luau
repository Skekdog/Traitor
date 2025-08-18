local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local UserInputService = game:GetService("UserInputService")
local Crouch = require(script.Parent.Crouch)
local LocalCharacter = require(ReplicatedStorage.Shared.Character.LocalCharacter)

local module = {}

local CLIMB_SPEED_MULTIPLIER = 0.75
local MIN_LADDER_HEIGHT = 2.5

local thread: thread?
local jumpRequestCon: RBXScriptConnection?

local currentClimbSoundIndex = 1
local CLIMB_SOUNDS: {Sound} = {}

for i, id in {84250734989129, 131423923611717, 132473964674158, 98963245122177} do
    local sound = Instance.new("Sound")
    sound.SoundId = "rbxassetid://" .. id
    sound.Volume = 0.5
    sound.SoundGroup = SoundService.AllSounds
    sound.Name = "ClimbSound" .. i
    sound.Parent = SoundService
    table.insert(CLIMB_SOUNDS, sound)
end

local function setStates(hum: Humanoid, enabled: boolean): ()
    hum:SetStateEnabled(Enum.HumanoidStateType.Freefall, enabled)
    hum:SetStateEnabled(Enum.HumanoidStateType.Climbing, not enabled)
    hum:SetStateEnabled(Enum.HumanoidStateType.Swimming, enabled)
    hum:ChangeState(if enabled then Enum.HumanoidStateType.Freefall else Enum.HumanoidStateType.Climbing)
    hum.PlatformStand = not enabled
    hum.AutoRotate = enabled
end

function module.Climb(ladder: BasePart): ()
    module.StopClimbing()
    Crouch.SetCrouchDisabled("Climbing", true)

    local char = LocalCharacter.Character()
    if not char then
        return
    end

    local root = LocalCharacter.RootPart()
    if not root then
        return
    end

    local hum = LocalCharacter.Humanoid()
    if not hum then
        return
    end

    currentClimbSoundIndex = 1

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
    ladderAttachment.Position = Vector3.new(0, math.clamp(ladder.CFrame:PointToObjectSpace(root.Position).Y, -ladderHeight + MIN_LADDER_HEIGHT, ladderHeight), -1)

    local worldRot = ladderAttachment.WorldOrientation
    char:PivotTo(CFrame.new(char:GetPivot().Position) * CFrame.Angles(0, math.rad(worldRot.Y + 180), 0))
    -- note: we add 180 because that's what the ladders in mesa monocraft demand, so it's probably a tt standard

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
            elseif not CLIMB_SOUNDS[currentClimbSoundIndex].IsPlaying then
                currentClimbSoundIndex = if currentClimbSoundIndex == #CLIMB_SOUNDS then 1 else currentClimbSoundIndex + 1
                CLIMB_SOUNDS[currentClimbSoundIndex]:Play()
            end

            local cameraLook = workspace.CurrentCamera.CFrame.LookVector

            if cameraLook.Y < -0.85 then
                z *= -1
            end

            local lastY = ladderAttachment.Position.Y

            local speed = hum.WalkSpeed * CLIMB_SPEED_MULTIPLIER
            ladderAttachment.Position = Vector3.new(0, math.clamp(lastY + (dt * speed * -math.sign(z)), -ladderHeight + MIN_LADDER_HEIGHT, ladderHeight + MIN_LADDER_HEIGHT), -1)

            if ladderAttachment.Position.Y >= ladderHeight + MIN_LADDER_HEIGHT or ladderAttachment.Position.Y <= -ladderHeight + MIN_LADDER_HEIGHT then
                task.defer(module.StopClimbing) -- We can't stop the current thread because its the current thread, so defer it to stop
            end
        end
    end)
    assert(thread)

    coroutine.resume(thread)
end

function module.StopClimbing(): ()
    Crouch.SetCrouchDisabled("Climbing", false)
    if jumpRequestCon then
        jumpRequestCon:Disconnect()
    end

    if thread then
        coroutine.close(thread)
    end

    local root = LocalCharacter.RootPart()
    if not root then
        return
    end

    local hum = LocalCharacter.Humanoid()
    if not hum then
        return
    end
    setStates(hum, true)

    local climbSound = root:FindFirstChild("ClimbSound") :: Sound?
    if climbSound then
        climbSound:Destroy()
    end

    local alignPos = root:FindFirstChild("LadderPositionAlignment") :: AlignPosition?
    if alignPos and alignPos.Enabled then
        alignPos.Enabled = false
    end
end

return module