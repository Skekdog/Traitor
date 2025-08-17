local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local IsAboveWater = require(script.Parent.IsAboveWater)
local LocalRoundInfo = require(ReplicatedStorage.Shared.LocalState.LocalRoundInfo)
local PlaySound = require(ReplicatedStorage.Shared.RoundRule.Common.PlaySound)
local LocalCharacter = require(script.Parent.LocalCharacter)

local function checkForWater(root: BasePart): boolean
    local map = LocalRoundInfo.Map()
    if not map then
        return false
    end

    for _, v in root:GetTouchingParts() do
        if v:HasTag("WaterLoaded") then
			return true
        end
    end

    -- The landed state often triggers really early so we do need to raycast quite far down. Testing on the Test map shows that -7.5 should suffice but I'll go -10 to be sure
    return IsAboveWater(map, root, 10)
end

LocalCharacter.Humanoid:Connect(function(hum)
	if not hum then
		return
	end

	hum.StateChanged:Connect(function(_, state)
		if state ~= Enum.HumanoidStateType.Landed then
			return
		end

		local root = LocalCharacter.RootPart()
		if not root then
			return
		end

		if checkForWater(root) then
			return
		end

		local velocity = math.abs(root.AssemblyLinearVelocity.Y)

		if velocity <= 45 then
			return
		end

		PlaySound(18782450650, nil, root, {
			SoundGroup = SoundService.AllSounds :: SoundGroup,
			Volume = 0.45,

			PlaybackRegion = NumberRange.new(0.05, 60000)
		})

		ReplicatedStorage.Remotes.ClientServer.Fell:FireServer(velocity)
	end)
end)

LocalCharacter.RootPart:Connect(function(root)
	if not root then
		return
	end

	root:WaitForChild("Landing"):Destroy()
end)

return nil