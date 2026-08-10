local MemoryStoreService = game:GetService("MemoryStoreService")
local RunService = game:GetService("RunService")
local ServerId = require(script.Parent.ServerId)
local ServerInfo = require(script.Parent.ServerInfo)

if game.PrivateServerId ~= "" or RunService:IsStudio() then
	return nil
end

const TTL = 60
const INTERVAL = 30

const hashMap = MemoryStoreService:GetHashMap("ServerList")
const serverId = ServerId

task.spawn(function()
	while true do
		local success, err = pcall(hashMap.SetAsync, hashMap, serverId, ServerInfo.Get(), TTL)
		if not success then
			warn(err)
		end

		task.wait(INTERVAL) -- To be sure, it makes sense to use task.wait() after the async call, because SetAsync will reset the TTL after it is done.
	end
end)

game:BindToClose(function()
	hashMap:RemoveAsync(serverId)
end)

return nil