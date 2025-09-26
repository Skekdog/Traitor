local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GetRemoteBack = require(ReplicatedStorage.Shared.GameDefinition.Items.Common.GetRemote)

local function GetRemote(name: string, parent: Instance): RemoteEvent
	return GetRemoteBack(name, parent)
end

return GetRemote