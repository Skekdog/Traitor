local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DynamicValue = require(ReplicatedStorage.Shared.Util.DynamicValue)

local module = {}

local plr = Players.LocalPlayer

module.Character = DynamicValue.new(nil :: Model?)
module.Humanoid = DynamicValue.new(nil :: Humanoid?)
module.RootPart = DynamicValue.new(nil :: BasePart?)
module.Head = DynamicValue.new(nil :: BasePart?)

plr:GetPropertyChangedSignal("Character"):Connect(function(): ()
	local char = plr.Character

	module.Character:SetValue(char)

	if not char then
		module.Humanoid:SetValue(nil)
		module.RootPart:SetValue(nil)
		module.Head:SetValue(nil)
		return
	end

	char.ChildAdded:Connect(function(child)
		if child:IsA("BasePart") then
			if child.Name == "Head" then
				module.Head:SetValue(child)
			elseif child.Name == "HumanoidRootPart" then
				module.RootPart:SetValue(child)
			end
		elseif child:IsA("Humanoid") then
			if child.Name == "Humanoid" then
				module.Humanoid:SetValue(child)
			end
		end
	end)

	local hum = char:FindFirstChild("Humanoid")
	assert(not hum or hum:IsA("Humanoid"), "Humanoid is not a Humanoid")

	module.Humanoid:SetValue(hum)

	local root = char:FindFirstChild("HumanoidRootPart")
	assert(not root or root:IsA("BasePart"), "Root is not a BasePart")

	module.RootPart:SetValue(root)

	local head = char:FindFirstChild("Head")
	assert(not head or head:IsA("BasePart"), "Head is not a BasePart")

	module.Head:SetValue(head)
end)

return table.freeze(module)