local ServerScriptService = game:GetService("ServerScriptService")
local RoundHandler = require(ServerScriptService.RoundHandler)

local lastPauseAttribute = false
task.spawn(function()
	while true do
		task.wait()
		local round = RoundHandler.Round()

		local success, map = pcall(round.GetMap, round)
		-- this sometimes throws an error when we skip the intermission phase.
		-- I know why it does that, it's because we task.defer the new round,
		-- but that's needed because of some stupid bullshit with how scripts load
		if not success then
			return
		end

		if not map.Definition.Extras or not map.Definition.Extras.CompatibilityMode then
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
end)


return nil