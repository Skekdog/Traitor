local RunService = game:GetService("RunService")

local function GetRemote(name: string, parent: Instance?, isUnreliable: boolean?)
	local remote: RemoteEvent | UnreliableRemoteEvent
	if RunService:IsServer() then
		remote = if isUnreliable then Instance.new("UnreliableRemoteEvent") else Instance.new("RemoteEvent")
		;(remote :: Instance).Name = name
		;(remote :: Instance).Parent = parent or script
	else
		local found = (parent or script :: Instance):WaitForChild(name)
		assert(found:IsA("RemoteEvent") or found:IsA("UnreliableRemoteEvent"), name .. " must be a RemoteEvent")
		remote = found
	end

	return remote
end

return GetRemote :: ((name: string, parent: Instance?) -> RemoteEvent) & ((name: string, parent: Instance?, isUnreliable: boolean) -> UnreliableRemoteEvent)