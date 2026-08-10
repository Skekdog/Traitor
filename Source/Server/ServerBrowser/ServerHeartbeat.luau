local HttpService = game:GetService("HttpService")
local MemoryStoreService = game:GetService("MemoryStoreService")
local RunService = game:GetService("RunService")
local ServerInfo = require(script.Parent.ServerInfo)

if game.PrivateServerId ~= "" then
	return nil
end

const TTL = 60
const INTERVAL = 30

const hashMap = MemoryStoreService:GetHashMap("ServerList")
const serverId = if RunService:IsStudio() then HttpService:GenerateGUID(false) else game.JobId

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