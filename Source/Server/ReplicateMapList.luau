local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

for _, child in ServerStorage.Maps:GetChildren() do
	local object = Instance.new("Configuration")
	object.Name = child.Name
	object.Parent = ReplicatedStorage.Assets.ReplicatedMapList
end

return nil