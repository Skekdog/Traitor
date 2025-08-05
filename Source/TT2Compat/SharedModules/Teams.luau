local ServerScriptService = game:GetService("ServerScriptService")
local RoundHandler = require(ServerScriptService.RoundHandler)

local Teams = {}

setmetatable(Teams, {
	__index = function(self, index: unknown): string?
		if typeof(index) ~= "Instance" or not index:IsA("Player") then
			return nil
		end

		local participant = RoundHandler.GetRound():GetParticipant(index.Name)
		if not participant then
			return nil
		end

		return participant:GetRole().Definition.Name
	end
})

return Teams