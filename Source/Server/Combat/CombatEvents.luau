local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local RoundHandler = require(ServerScriptService.RoundHandler)
local Types = require(ReplicatedStorage.API.Types)

local remotes = ReplicatedStorage.Remotes

remotes.ClientServer.EquipItem.OnServerEvent:Connect(function(plr, itemName: unknown)
	if itemName and typeof(itemName) ~= "string" then
		return
	end

	local participant = RoundHandler.GetRound():GetParticipant(plr.Name)
	if not participant then
		return
	end

	if not itemName then
		return participant:SetEquippedItem()
	end

	local item = participant:GetItems()[itemName]
	if not item then
		return participant:SetEquippedItem()
	end

	participant:SetEquippedItem(item)
end)

local function finishReloading(plr: Player, item: Types.Item): ()
	item.IsReloading = false
	remotes.ClientServer.ReloadWeapon:FireClient(plr, item.Name, item.Ammo)
end

local function updateAmmo(plr: Player, item: Types.Item): ()
	remotes.ServerClient.UpdateAmmo:FireClient(plr, item.Name, item.Ammo)
end

remotes.ClientServer.ReloadWeapon.OnServerEvent:Connect(function(plr, itemName: unknown): ()
	if typeof(itemName) ~= "string" then
		return
	end

	local participant = RoundHandler.GetRound():GetParticipant(plr.Name)
	if not participant then
		return
	end

	local item = participant:GetEquippedItem()
	if not item or item.Name ~= itemName or not item.AmmoDefinition then
		return
	end

	if item.IsReloading then
		return
	end

	if item.Ammo >= item.AmmoDefinition.Capacity then
		return
	end

	-- take care: we shouldn't store the GetAmmo result, as the player may pick up more ammo whilst reloading

	local ammoKind = item.AmmoDefinition.Name
	if participant:GetAmmo(ammoKind) <= 0 then
		return
	end

	item.IsReloading = true

	if not item.ReloadDuration or item.ReloadDuration <= 0 then
		finishReloading(plr, item)
	else
		if item.UseShells then
			local elapsed = 0
			while (item.Ammo or 0) < item.AmmoDefinition.Capacity and participant:GetAmmo(ammoKind) > 0 do
				if participant:GetEquippedItem() ~= item then
					finishReloading(plr, item)
					return
				end

				if elapsed > item.ReloadDuration :: number then
					elapsed = 0
					item.Ammo = (item.Ammo or 0) + 1
					participant:SetAmmo(ammoKind, participant:GetAmmo(ammoKind) - 1)
					updateAmmo(plr, item)
				end

				elapsed += RunService.Heartbeat:Wait()
			end
			finishReloading(plr, item)
			return
		else
			local endTime = workspace:GetServerTimeNow() + item.ReloadDuration
			while workspace:GetServerTimeNow() < endTime do
				if participant:GetEquippedItem() ~= item then
					finishReloading(plr, item)
					return
				end
				task.wait()
			end
		end
	end

	local diff = math.clamp(participant:GetAmmo(ammoKind), 0, item.AmmoDefinition.Capacity - (item.Ammo or 0))
	participant:SetAmmo(ammoKind, participant:GetAmmo(ammoKind) - diff)
	item.Ammo = (item.Ammo or 0) + diff

	finishReloading(plr, item)
end)

remotes.ClientServer.DropItem.OnServerEvent:Connect(function(plr, itemName: unknown, direction: unknown): ()
	if typeof(itemName) ~= "string" then
		return
	end

	if typeof(direction) ~= "Vector3" then
		return
	end

	if direction.Magnitude > 1.1 then
		return
	end

	local participant = RoundHandler.GetRound():GetParticipant(plr.Name)
	if not participant then
		return
	end

	local item = participant:GetItems()[itemName]
	if not item or not item.ItemGroup then
		return
	end

	participant:DropItem(item, direction)
end)

remotes.ClientServer.DropAmmo.OnServerEvent:Connect(function(plr, itemName: unknown, direction: unknown): ()
	if typeof(itemName) ~= "string" then
		return
	end

	if typeof(direction) ~= "Vector3" then
		return
	end

	if direction.Magnitude > 1.1 then
		return
	end

	local round = RoundHandler.GetRound()

	local participant = round:GetParticipant(plr.Name)
	if not participant then
		return
	end

	local item = participant:GetItems()[itemName]
	if not item then
		return
	end

	if not item.AmmoDefinition or not item.AmmoDefinition.CanDrop then
		return
	end

	if (item.Ammo or 0) < item.AmmoDefinition.Capacity / 4 then
		return
	end

	local char = participant:GetCharacter()
	if not char then
		return
	end

	local head = char:FindFirstChild("Head")
	if not head or not head:IsA("BasePart") then
		return
	end

	local amount = item.Ammo or 0
	local model = assert(item.AmmoDefinition.Model):Clone()

	if not participant:TryThrowAssembly(model, 15, nil, nil, direction) then
		return
	end

	item.Ammo = 0
	remotes.ServerClient.UpdateAmmo:FireClient(plr, item.Name, 0);

	round:LoadProp(model)
	local ammoBox = round:GetAmmoBox(model)
	assert(ammoBox)
	ammoBox:SetAmmo(amount)
end)

return nil