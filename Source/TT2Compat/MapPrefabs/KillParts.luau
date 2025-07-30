local ServerScriptService = game:GetService("ServerScriptService")
local RoundHandler = require(ServerScriptService.RoundHandler)

local function kill(part: BasePart, damageSource: string): ()
	local char = part:FindFirstAncestorOfClass("Model")
	if not char then
		return
	end

	local round = RoundHandler.GetRound()
	local participant = round:GetParticipantFromCharacter(char)

	if participant then
		participant:TryTakeDamage({
			Amount = math.huge,
			Source = "Other", -- todo: map tt2 damage sources to tyt sources
		})
	end
end

local function KillParts(parts: {BasePart}, damageSource: string): ()
	for _, part in parts do
		part.Touched:Connect(function(otherPart: BasePart): ()
			kill(otherPart, damageSource)
		end)
	end
end

return KillParts