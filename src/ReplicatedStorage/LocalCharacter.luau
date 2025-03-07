local Players = game:GetService("Players")

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

return module