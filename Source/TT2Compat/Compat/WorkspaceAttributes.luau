local ServerScriptService = game:GetService("ServerScriptService")
local RoundHandler = require(ServerScriptService.RoundHandler)

RoundHandler.Round:Connect(function(round)
	local lastPauseAttribute = false
	while true do
		task.wait()
		if not round:GetMap().Extras.CompatibilityMode then
			continue
		end
		if round:IsPreGame() then
			workspace:SetAttribute("RoundState", "Preparing")
		elseif round:IsInProgress() then
			workspace:SetAttribute("RoundState", "In progress")
		elseif round:IsPostGame() then
			workspace:SetAttribute("RoundState", "Round over")
		end

		local pauseAttribute = workspace:GetAttribute("Paused") ~= nil
		if workspace:GetAttribute("Paused") ~= lastPauseAttribute then
			-- This means that something else changed the pause state, so we update accordingly
			round:Pause(pauseAttribute)
		end

		lastPauseAttribute = round:IsPaused()
		workspace:SetAttribute("Paused", round:IsPaused())
	end
end, true)

return nil