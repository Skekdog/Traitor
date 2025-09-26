local RunService = game:GetService("RunService")

local function GetRemote(name: string, parent: Instance?): RemoteEvent
	local remote: RemoteEvent
	if RunService:IsServer() then
		remote = Instance.new("RemoteEvent")
		remote.Name = name
		remote.Parent = parent or script
	else
		local found = (parent or script :: Instance):WaitForChild(name)
		assert(found:IsA("RemoteEvent"), name .. " must be a RemoteEvent")
		remote = found
	end
	return remote
end

return GetRemote