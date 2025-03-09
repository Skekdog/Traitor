local Players = game:GetService("Players")
local Connection = require(script.Parent.Connection)

local module = {}

local plr = Players.LocalPlayer

function module.GetCharacter(): Model?
	return plr.Character
end

function module.GetHumanoid(): Humanoid?
	local char = module.GetCharacter()
	return if char then char:FindFirstChildOfClass("Humanoid") else nil
end

function module.GetRootPart(): BasePart?
	local hum = module.GetHumanoid()
	return if hum then hum.RootPart else nil
end

function module.GetHead(): BasePart?
	local char = module.GetCharacter()
	if not char then
		return nil
	end

	local head = char:FindFirstChild("Head")
	
	return if head and head:IsA("BasePart") then head else nil
end

module.CharacterAdded = Connection.new((nil :: any) :: Model)
module.HumanoidAdded = Connection.new((nil :: any) :: Humanoid)

plr.CharacterAdded:Connect(function(char)
	module.CharacterAdded:Invoke(char)

	local hum = char:WaitForChild("Humanoid")
	assert(hum:IsA("Humanoid"), "Humanoid is not a Humanoid")

	module.HumanoidAdded:Invoke(hum)
end)

return module