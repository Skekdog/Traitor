local RunService = game:GetService("RunService")

local function GetRemote(name: string): RemoteEvent
	local remote: RemoteEvent
	if RunService:IsServer() then
		remote = Instance.new("RemoteEvent")
		remote.Name = name
		remote.Parent = script
	else
		local found = script:WaitForChild(name)
		assert(found:IsA("RemoteEvent"), name .. " must be a RemoteEvent")
		remote = found
	end
	return remote
end

return GetRemote