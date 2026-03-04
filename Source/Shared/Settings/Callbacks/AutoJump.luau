local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalCharacter = require(ReplicatedStorage.Shared.Character.LocalCharacter)

local enabled = false

local function update(humanoid: Humanoid): ()
	humanoid.AutoJumpEnabled = enabled
end

LocalCharacter.Humanoid:Connect(function(humanoid)
	if humanoid then
		update(humanoid)
	end
end)

local function AutoJump(_, value: boolean): ()
	enabled = value

	local humanoid = LocalCharacter.Humanoid()
	if humanoid then
		update(humanoid)
	end
end

return AutoJump