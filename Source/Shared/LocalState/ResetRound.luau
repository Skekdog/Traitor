local Players = game:GetService("Players")
local HighlightForRoles = require(script.Parent.HighlightForRoles)
local LocalRoundInfo = require(script.Parent.LocalRoundInfo)

local function ResetRound(): ()
	for _, v in Players:GetPlayers() do
		v:SetAttribute("Mark", "")
	end

	workspace.Projectiles:ClearAllChildren()
	workspace.RadarPoints:ClearAllChildren()

	HighlightForRoles.Reset()
end

LocalRoundInfo.OnReset:Connect(ResetRound)

return ResetRound