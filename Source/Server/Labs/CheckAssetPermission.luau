local MarketplaceService = game:GetService("MarketplaceService")

local UPLOADER_ACCOUNT = 10474615021

local function CheckAssetPermission(assetId: number): ()
	local success, details = pcall(MarketplaceService.GetProductInfoAsync, MarketplaceService, assetId, Enum.InfoType.Asset)
	if not success then
		error("Failed to fetch asset details")
	end

	if details.CreatorType == "User" and details.CreatorTargetId == UPLOADER_ACCOUNT then
		local description: string = details.Description or ""
		local authorisedIds = description:split(",")

		local host = workspace:GetAttribute("ServerHost")

		local allowed = false
		for _, id in authorisedIds do
			if tonumber(id) == host then
				allowed = true
				break
			end
		end

		if not allowed then
			error("You do not have permission to load this asset.")
		end
	end
end

return CheckAssetPermission