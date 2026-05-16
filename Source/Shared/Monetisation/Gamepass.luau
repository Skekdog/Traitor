local MarketplaceService = game:GetService("MarketplaceService")

local Gamepass = {}

function Gamepass.PromptIfNotOwned(gamepassId: number, player: Player): boolean
	local isOwned = Gamepass.IsOwned(gamepassId, player)
	if not isOwned then
		MarketplaceService:PromptGamePassPurchase(player, gamepassId)
	end

	return isOwned
end

function Gamepass.IsOwned(gamepassId: number, player: Player): boolean
	return MarketplaceService:UserOwnsGamePassAsync(player.UserId, gamepassId)
end

return table.freeze(Gamepass)