local BadgeService = game:GetService("BadgeService")
local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

local ItemTypes = require(ReplicatedFirst.ItemTypes)
local InventoryManager = require(ServerScriptService.InventoryManagerServer)
local ProfileManager = require(script.Parent.ProfileManager)

local _earlyTesters = { -- These players should be awarded the badge whenever they join, even after release
	465187670,
	16481979,
	2356511943,
	315415902,
	305546034,
	2021782328,
	157359649,
	435767054,
	120380298,
	1939149799,
	879872945,
	1217524874,
	1914198146,
	507682950,
	706326447,
	629091420,
	519873663,
	19990629,
	4132746558,
	3541273531,
	4051361442,
	3106058458
}

Players.PlayerAdded:Connect(function(plr): ()
	if ServerStorage:GetAttribute("ServerLocked") then
		return plr:Kick("This server is shutting down.")
	end
	
    local profile = ProfileManager.LoadProfile(plr)
	plr:SetAttribute("Score", 0)
	plr:SetAttribute("TotalScore", 0)
	if profile then
        ReplicatedStorage.ServerClient.LoadSavedData:FireClient(plr, profile.Data.Settings)
		plr:SetAttribute("TotalScore", profile.Data.TotalPoints)
    end

	InventoryManager.InitInventory(plr)

	local tries = 0
	local suc = false
	repeat
		suc = pcall(function()
			BadgeService:AwardBadge(plr.UserId, 2136698808)
		end)
		task.wait(1)
	until suc or tries > 3
end)

Players.PlayerRemoving:Connect(function(plr)
	ProfileManager.ReleaseProfile(plr)
	InventoryManager.DeInitInventory(plr)
end)

ReplicatedStorage.ClientServer.SaveSettings.OnServerEvent:Connect(function(plr, options: unknown)
	if typeof(options) ~= "string" then
		return
	end
	if options:len() > ProfileManager.ProfileTemplate.Settings:len()*1.2 then
		return warn("Settings length exceeds maximum "..tostring(ProfileManager.ProfileTemplate.Settings:len()*1.2).." characters!")
	end

    ProfileManager.UpdateProfile(plr, "Settings", options)
end)

local function fireInventoryClient(plr: Player, event: InventoryManager.InventoryEvent, equipment: ItemTypes.Item, params: ItemTypes.ClientItemInitParams?)
	InventoryManager.InvEvent:FireClient(plr, event, equipment.Base.Name, params)
end

InventoryManager.Listen("Add", function(plr, equipment)
	local params: ItemTypes.ClientItemInitParams?
	if equipment.Kind == "Gun" then
		params = {
			LastFireTime = equipment.LastFireTime,
			CurrentAmmo = equipment.CurrentAmmo,
			ReloadingUntil = equipment.ReloadingUntil,
		}
	elseif equipment.Kind == "Melee" then
		params = {
			LastFireTime = equipment.LastFireTime,
		}
	end
	fireInventoryClient(plr, "Add", equipment, params or nil)
end)

InventoryManager.Listen("Remove", function(plr, equipment)
	fireInventoryClient(plr, "Remove", equipment)
end)

InventoryManager.Listen("Equip", InventoryManager.UpdateAmmo)

InventoryManager.Listen("Unequip", function(plr, equipment)
	if equipment.Kind ~= "Gun" then
		return
	end

	if equipment.Reloading then
		task.cancel(equipment.Reloading)
		equipment.Reloading = nil
		ReplicatedStorage.ServerClient.SetReloadingStatus:FireClient(plr, equipment.Base.Name)

		if plr.Character and plr.Character.PrimaryPart then
			local sound = plr.Character.PrimaryPart:FindFirstChild("ReloadSound") :: Sound?
			if sound then
				sound:Stop()
			end
		end
	end
end)

InventoryManager.InvEvent.OnServerEvent:Connect(function(plr: Player, event: unknown, equipmentName: unknown, switching: unknown, cameraRayInfo: unknown)
	if typeof(equipmentName) ~= "string" then
		return
	end

	local inventory = InventoryManager.GetInventory(plr)
	local foundEquipment: ItemTypes.Item?
	for _, v in inventory do
		if v.Base.Name == equipmentName then
			foundEquipment = v
			break
		end
	end

	local char = plr.Character
	if not foundEquipment or not char or not char.PrimaryPart then
		return
	end

	if event == "Equip" then
		InventoryManager.Equip(plr, foundEquipment)
	elseif event == "Unequip" then
		InventoryManager.Unequip(plr, foundEquipment, switching :: boolean?)
	elseif event == "Drop" then
		if typeof(cameraRayInfo) ~= "Ray" then
			return
		end
		InventoryManager.Drop(plr, foundEquipment, char:GetPivot().Position + cameraRayInfo.Direction.Unit * 10)
	end
end)

ReplicatedStorage.ClientServer.RotateHead.OnServerEvent:Connect(function(plr, y: unknown)
	local char = plr.Character
	if not char then
		return
	end

	if typeof(y) ~= "number" then
		return
	end

	local neck = char:FindFirstChild("Neck", true) :: Motor6D
	if not neck then
		return
	end

	y = math.clamp(y, -1.4, 1.4)
	neck.C0 = CFrame.new(neck.C0.Position) * CFrame.Angles(y, 0, 0)
end)

ReplicatedStorage.ClientServer.GetKarma.OnServerInvoke = function(plr, target: unknown)
	if typeof(target) ~= "Instance" or not target:IsA("Player") then
		return
	end
	local profile = ProfileManager.GetProfile(plr)
	return if profile then profile.Karma else 1000
end

require(script.Parent.MagnetoStick)