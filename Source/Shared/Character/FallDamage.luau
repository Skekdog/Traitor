local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Audio = require(ReplicatedStorage.API.Audio)
local CalculateFallDamage = require(script.Parent.CalculateFallDamage)
local IsAboveWater = require(script.Parent.IsAboveWater)
local LocalRoundInfo = require(ReplicatedStorage.Shared.LocalState.LocalRoundInfo)
local LocalCharacter = require(script.Parent.LocalCharacter)

local FALL_SOUND = Audio.MakeSound({
	Content = Content.fromAssetId(18782450650),
	Volume = 0.45,
	PlaybackRegion = NumberRange.new(0.05, 60000)
})

local function checkForWater(root: BasePart): boolean
    local map = LocalRoundInfo.Map()
    if not map then
        return false
    end

    for _, v in root:GetTouchingParts() do
        if v:HasTag("Water") then
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
		local damage = CalculateFallDamage(velocity)
		if damage == 0 then
			return
		end

		Audio.PlayIn(FALL_SOUND, root)

		ReplicatedStorage.Remotes.ClientServer.Fell:FireServer(velocity, root.Position)
	end)
end)

LocalCharacter.RootPart:Connect(function(root)
	if not root then
		return
	end

	task.spawn(function()
		local landingSound = root:WaitForChild("Landing")
		if landingSound:IsA("AudioPlayer") then
			landingSound.Volume = 0 -- Destroying causes the built-in RbxCharacterSounds script to warn about indefinite WaitForChild
		end
	end)
end)

return nil