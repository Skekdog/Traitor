local BadgeService = game:GetService("BadgeService")
local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local TeleportService = game:GetService("TeleportService")

local ItemTypes = require(script.Parent.Parent.ReplicatedFirst.ItemsManager.ItemTypes)
local RoundHandler = require(ReplicatedFirst.RoundHandler.RoundHandler)
local InventoryManager = require(ReplicatedFirst.InventoryManager)
local ProfileManager = require(script.Parent.ProfileManager)
local RestartServer = require(script.Parent.RestartServer)

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
local meId = 965735486
local testPlace = 9648179685

Players.PlayerAdded:Connect(function(plr)
	if ServerStorage:GetAttribute("ServerLocked") then
		return plr:Kick("This server is shutting down.")
	end
	
    local profile = ProfileManager.LoadProfile(plr)
	if profile then
        ReplicatedStorage.ServerClient.LoadSavedData:FireClient(plr, profile.Data.Settings)
    end

	InventoryManager.InitInventory(plr)

	plr.Chatted:Connect(function(msg, to)
        if to then
            return
        end

        msg = msg:lower()

        if msg == "!testplace" and game.PlaceId ~= testPlace then
            local targets = {plr}
			if plr.UserId == meId then
				targets = Players:GetPlayers()
			end
			TeleportService:TeleportAsync(testPlace, targets)
        elseif msg == "!pause" and plr.UserId == meId then
            local id = ServerStorage:GetAttribute("RoundID")
			if not id then
				return
			end

            local round = RoundHandler.GetRound(id)
            if not round:IsRoundInProgress() then
                return
            end

            round:PauseRound()

            if not round.Paused then
                ReplicatedStorage.RoundHandler:SetAttribute("TimeMilestone", round.TimeMilestone)
            end
            ReplicatedStorage.RoundHandler:SetAttribute("IsPaused", round.Paused)
        elseif msg == "!restart" and plr.UserId == meId then
            RestartServer(5)
        end
    end)

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

ReplicatedStorage.ClientServer.SaveSettings.OnServerEvent:Connect(function(plr, options: string?)
	if typeof(options) ~= "string" then
		return
	end
	if options:len() > ProfileManager.ProfileTemplate.Settings:len()*1.2 then
		return warn("Settings length exceeds maximum "..tostring(ProfileManager.ProfileTemplate.Settings:len()*1.2).." characters!")
	end

    ProfileManager.UpdateProfile(plr, "Settings", options)
end)

local function fireInventoryClient(plr: Player, event: InventoryManager.InventoryEvent, equipment: ItemTypes.Item)
	InventoryManager.InvEvent:FireClient(plr, event, equipment)
end

InventoryManager.Listen("Add", function(plr, equipment)
	fireInventoryClient(plr, "Add", equipment)
end)

InventoryManager.Listen("Remove", function(plr, equipment)
	fireInventoryClient(plr, "Remove", equipment)
end)

InventoryManager.InvEvent.OnServerEvent:Connect(function(plr: Player, event: InventoryManager.InventoryEvent?, equipmentName: string?)
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
		InventoryManager.Unequip(plr, foundEquipment)
	elseif event == "Drop" then
		InventoryManager.Drop(plr, foundEquipment, char:GetPivot().Position + char.PrimaryPart.CFrame.LookVector * 10)
	end
end)

ReplicatedStorage.ClientServer.RotateHead.OnServerEvent:Connect(function(plr, y: number)
	local char = plr.Character
	if not char then
		return
	end

	local neck = char:FindFirstChild("Neck", true) :: Motor6D
	if not neck then
		return
	end

	y = math.clamp(y, -1.4, 1.4)
	neck.C0 = CFrame.new(neck.C0.Position) * CFrame.Angles(y, 0, 0)
end)

ReplicatedStorage.ClientServer.GetKarma.OnServerInvoke = function(plr, target)
	local profile = ProfileManager.GetProfile(plr)
	return profile and profile.Karma or 1000
end