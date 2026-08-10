local MemoryStoreService = game:GetService("MemoryStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SharedTypes = require(ReplicatedStorage.Shared.SharedTypes)

local servers: {[string]: SharedTypes.ServerInfo} = {}
const hashMap = MemoryStoreService:GetHashMap("ServerList")

const UPDATE_INTERVAL = 30
const MAX_PER_PAGE = 200

task.spawn(function()
	while true do
		local pages = hashMap:ListItemsAsync(MAX_PER_PAGE)

		local newServers: {[string]: SharedTypes.ServerInfo} = {}
		while not pages.IsFinished do
			local items = pages:GetCurrentPage()
			for _, entry: {key: string, value: SharedTypes.ServerInfo} in items do
				newServers[entry.key] = entry.value
			end

			if not pages.IsFinished then
				pages:AdvanceToNextPageAsync()
			end
		end

		servers = newServers

		task.wait(UPDATE_INTERVAL)
	end
end)

ReplicatedStorage.Remotes.ClientServer.FetchServerList.OnServerInvoke = function(player): {[string]: SharedTypes.ServerInfo}
	return servers
end

return nil