local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.RoundRule.Types)
local ClientInventory = require(script.Parent.ClientInventory)
local ControlManager = require(script.Parent.ControlManager)
local LocalRoundInfo = require(script.Parent.LocalRoundInfo)

local player = Players.LocalPlayer

local function getCharacter(): Model?
	return player.Character
end

local function getCenterRay(): Ray
    local camera = workspace.CurrentCamera
    return camera:ViewportPointToRay(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
end

local function raycast(head: BasePart): RaycastResult?
	local map = LocalRoundInfo.GetMap()
	if not map then
		return
	end

	local params = RaycastParams.new()
	params.FilterDescendantsInstances = {map.Bounds, assert(head:FindFirstAncestorOfClass("Model"))}
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.IgnoreWater = true
	params.RespectCanCollide = true

	return workspace:Raycast(head.Position, getCenterRay().Direction * 10000, params)
end

player.CharacterRemoving:Connect(function()
	ControlManager.Unregister("Primary Fire")
end)

ClientInventory.ConnectEquippedItemChanged(function(item): ()
	local char = getCharacter()
	if not item or not char then
		print(1)
		return ControlManager.Unregister("Primary Fire")
	end

	ControlManager.Register("Primary Fire", true, function(_, _, input)
		while ClientInventory.EquippedItem == item and input.UserInputState ~= Enum.UserInputState.End and input.UserInputState ~= Enum.UserInputState.Cancel do
			task.wait()
			if item.Kind == "Gun" and item.Ammo < 0 then
				print(2)
				continue
			end

			if item.Kind == "Melee" or item.Kind == "Gun" then
				if item.LastAttackTime + item.Definition.AttackInterval > tick() then
					print(3)
					continue
				end
				(item :: Types.GunWeapon).LastAttackTime = tick()
			end

			local head = char:WaitForChild("Head")
			assert(head and head:IsA("BasePart"), "HumanoidRootPart is not a BasePart")

			local raycastResult = raycast(head)
			if not raycastResult then
				print(4)
				continue
			end

			local ownPosition = head.Position
			local targetPosition = raycastResult.Position
			local hitPart = raycastResult.Instance :: BasePart
			local hitPartCenterPosition = hitPart.Position
			local itemName = item.Definition.Name

			ReplicatedStorage.ClientServer.PrimaryFire:FireServer(ownPosition, targetPosition, hitPart, hitPartCenterPosition, itemName)
		end

		return Enum.ContextActionResult.Sink
	end)
end)
