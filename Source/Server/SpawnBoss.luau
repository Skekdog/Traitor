local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RoundHandler = require(script.Parent.RoundHandler)

ReplicatedStorage.Remotes.ClientServer.SpawnBoss.OnServerEvent:Connect(function(player, bossName: unknown)
	if typeof(bossName) ~= "string" then
		return
	end

	local round = RoundHandler.Round()
	local map = round:GetMap()
	local definition = map.Bosses[bossName]

	if not definition then
		return
	end

	if map.Structure.Static:GetAttribute("BossSpawned") then
		return
	end

	if definition.GamepassId and not MarketplaceService:UserOwnsGamePassAsync(player.UserId, definition.GamepassId) then
		return
	end

	round:LoadBoss(definition)
end)

return nil