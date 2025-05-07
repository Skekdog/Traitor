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

	local hum = char:WaitForChild("Humanoid")
	assert(hum:IsA("Humanoid"), "Humanoid is not a Humanoid")

	module.Humanoid:SetValue(hum)

	module.RootPart:SetValue(hum.RootPart)
	
	local head = char:WaitForChild("Head")
	assert(head:IsA("BasePart"), "Head is not a BasePart")

	module.Head:SetValue(head)
end)

return module