local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DynamicValue = require(ReplicatedStorage.Shared.Util.DynamicValue)

local module = {}

local plr = Players.LocalPlayer

type Controllers = {
	Manager: ControllerManager,
	Ground: GroundController,
	Climb: ClimbController,
	Swim: SwimController,
	Air: AirController,
}

type Sensors = {
	Buoyancy: BuoyancySensor,
	Floor: ControllerPartSensor,
	Ladder: ControllerPartSensor,
}

module.Character = DynamicValue.new(nil :: Model?)
module.Humanoid = DynamicValue.new(nil :: Humanoid?)
module.RootPart = DynamicValue.new(nil :: BasePart?)
module.Head = DynamicValue.new(nil :: BasePart?)
module.Controllers = DynamicValue.new<<Controllers?>>(nil)
module.Sensors = DynamicValue.new<<Sensors?>>(nil)

plr:GetPropertyChangedSignal("Character"):Connect(function(): ()
	local char = plr.Character

	module.Character:SetValue(char)

	if not char then
		module.Controllers:SetValue(nil)
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
		elseif child:IsA("ControllerManager") then
			local controllers: Controllers = {
				Manager = child,
				Ground = assert(child:FindFirstChildOfClass("GroundController")),
				Climb = assert(child:FindFirstChildOfClass("ClimbController")),
				Swim = assert(child:FindFirstChildOfClass("SwimController")),
				Air = assert(child:FindFirstChildOfClass("AirController")),
			}

			module.Controllers:SetValue(controllers)
		end
	end)

	local controllerManager = char:FindFirstChild("ControllerManager")
	assert(not controllerManager or controllerManager:IsA("ControllerManager"), "ControllerManager is not a ControllerManager")

	if controllerManager then
		local controllers: Controllers = {
			Manager = controllerManager,
			Ground = assert(controllerManager:FindFirstChildOfClass("GroundController")),
			Climb = assert(controllerManager:FindFirstChildOfClass("ClimbController")),
			Swim = assert(controllerManager:FindFirstChildOfClass("SwimController")),
			Air = assert(controllerManager:FindFirstChildOfClass("AirController")),
		}

		module.Controllers:SetValue(controllers)
	end

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

module.RootPart:Connect(function(root)
	if not root then
		module.Sensors:SetValue(nil)
		return
	end

	local floorSensor = root:WaitForChild("FloorSensor")
	assert(floorSensor and floorSensor:IsA("ControllerPartSensor"), "FloorSensor is not a ControllerPartSensor")

	local ladderSensor = root:WaitForChild("LadderSensor")
	assert(ladderSensor and ladderSensor:IsA("ControllerPartSensor"), "LadderSensor is not a ControllerPartSensor")

	local buoyancySensor = root:WaitForChild("BuoyancySensor")
	assert(buoyancySensor and buoyancySensor:IsA("BuoyancySensor"), "BuoyancySensor is not a BuoyancySensor")

	local sensors: Sensors = {
		Floor = floorSensor,
		Ladder = ladderSensor,
		Buoyancy = buoyancySensor,
	}

	module.Sensors:SetValue(sensors)
end)

return table.freeze(module)