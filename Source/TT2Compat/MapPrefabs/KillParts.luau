local ServerScriptService = game:GetService("ServerScriptService")
local RoundHandler = require(ServerScriptService.RoundHandler)

local function onTouch(part: BasePart): ()
	local char = part:FindFirstAncestorOfClass("Model")
	if not char then
		return
	end

	local round = RoundHandler.GetRound()
	local participant = round:GetParticipantFromCharacter(char)

	if participant then
		participant:TryTakeDamage({
			Amount = math.huge,
			Source = "Other",
		})
	end
end

local function KillParts(parts: {BasePart}, _: nil): ()
	for _, part in parts do
		part.Touched:Connect(onTouch)
	end
end

return KillParts