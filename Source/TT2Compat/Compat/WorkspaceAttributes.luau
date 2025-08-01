local ServerScriptService = game:GetService("ServerScriptService")
local RoundHandler = require(ServerScriptService.RoundHandler)

RoundHandler.Round:Connect(function(round)
	while true do
		if not round:GetMap().Extras.CompatibilityMode then
			continue
		end
		task.wait()
		if round:IsPreGame() then
			workspace:SetAttribute("RoundState", "Preparing")
		elseif round:IsInProgress() then
			workspace:SetAttribute("RoundState", "In progress")
		elseif round:IsPostGame() then
			workspace:SetAttribute("RoundState", "Round over")
		end

		workspace:SetAttribute("Paused", round:GetIsRoundPaused())
	end
end, true)

return nil