local ServerScriptService = game:GetService("ServerScriptService")
local RoundHandler = require(ServerScriptService.RoundHandler)

local module = {}

function module.GiveItem(self, player: Player, itemName: string): ()
	local round = RoundHandler.GetRound()
	local participant = round:GetParticipant(player.Name)
	if not participant then
		return
	end

	local itemDefinition = round:GetItemDefinition(itemName)
	if not itemDefinition then
		return
	end
	participant:GiveItemFromItemDefinition(itemDefinition)
end

function module.SpawnItem(self, item: string, cframe: CFrame, _, _, _, _): ()
	
end

return module