local ServerScriptService = game:GetService("ServerScriptService")
local RoundHandler = require(ServerScriptService.RoundHandler)

local module = {}

function module.GiveItem(self, player: Player, itemName: string, ammo: number?, lastActivated: number?, lastAltActivated: number?, silent: boolean?, swap: boolean?): boolean
	local round = RoundHandler.GetRound()
	local participant = round:GetParticipant(player.Name)
	if not participant then
		return false
	end

	local itemDefinition = round:GetItemDefinition(itemName)
	if not itemDefinition then
		return false
	end

	if participant:IsItemSlotOccupied(itemDefinition.Slot or -1) then
		return false
	end

	participant:GiveItemFromItemDefinition(itemDefinition)
	return true
end

function module.SpawnItem(self, item: string, cframe: CFrame, _, _, _, _): ()
	local round = RoundHandler.GetRound()
	local definition = round:GetItemDefinition(item)
	if not definition or not definition.Model then
		return
	end

	local model = definition.Model:Clone()
	model.Parent = round:GetMap().ItemSpawns
	model:PivotTo(cframe)
	round:LoadProp(model, "ItemProp")
end

return module