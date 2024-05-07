--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local plr = game:GetService("Players").LocalPlayer
local UIManager = require(script.Parent.Parent)
local controls = require(game:GetService("ReplicatedFirst").ControlManager)

type SampleType = TextButton & {TextLabel: TextLabel, Value: ObjectValue & {Value: Instance & {Equipped: BindableEvent}}}
local screenUi = UIManager.WaitForUI("Backpack").UI :: Frame & {Sample: SampleType}

local clientStorage = game:WaitForChild("ClientStorage")
local scriptCons = clientStorage:WaitForChild("ScriptConnections") :: any

local function invAdded(child: Instance)
	if not screenUi:FindFirstChild(child.Name) then
		local sample = screenUi.Sample:Clone()
		sample.Name = tostring(child:GetAttribute("Slot"))..child.Name
		sample.Text = child.Name
		sample.TextLabel.Text = "["..(child:GetAttribute("Slot") or #screenUi:GetChildren()-3).."]"

		sample.Value.Value = child
		sample.Visible = true
		sample.Parent = screenUi

		sample.MouseButton1Click:Connect(function()
			equip(not child:GetAttribute("Equipped"), child, sample, false)
		end)
		
		scriptCons.InventoryChangedEvent:Fire(child, true)
	end
end

plr:GetPropertyChangedSignal("Character"):Connect(function()
	local char = plr.Character
	if not char then
		return
	end
	local hum = char:WaitForChild("Humanoid") :: Humanoid
	hum.Died:Connect(function()
		controls.Unregister("Primary Fire")
		controls.Unregister("Drop")
		controls.Unregister("Reload Weapon")
	end)
end)

local drop
local anims: {AnimationTrack} = {}
local ammoCons = {}
function equip(toEquip, tool, label: any, isServer)
	local char = plr.Character :: Model & {Humanoid: Humanoid}
	if not char then return end
	if char.Humanoid.Health <= 0 then return end
	ReplicatedStorage.ClientServer.AttachWeapon:FireServer(tool, toEquip)
	for i, v in screenUi:GetChildren() :: {SampleType} do
		if v:IsA("TextButton") and v.Name ~= "Sample" then
			v.TextTransparency = 0
			v.BackgroundTransparency = 0.75
			if v.Value.Value:GetAttribute("Equipped") and v.Name ~= tool.Name then
				v.Value.Value:SetAttribute("Equipped", false)
				v.Value.Value.Equipped:Fire(false)
			end
		end
	end
	for i, v in char:GetChildren() do
		if v:GetAttribute("Weapon") and v ~= tool then v:Destroy() end
	end
	scriptCons.EquipEvent:Fire(tool, toEquip)
	tool:SetAttribute("Equipped", toEquip)
	local roundInfo = UIManager.WaitForUI("RoundInfo").UI :: Frame & {Frame: any}
	local ammoBar = roundInfo.Frame.AmmoBar
	if toEquip then
		local curAmmo = tool:FindFirstChild("CurrentAmmo")
		local reload = tool.Configuration:FindFirstChild("Reload")
		local maxAmmo, infiniteAmmo
		if reload then
			maxAmmo, infiniteAmmo = reload:GetAttribute("MagCapacity"), reload:GetAttribute("InfiniteAmmo")
		end 
		if curAmmo and not infiniteAmmo then
			local function updateAmmo()
				local ammo = curAmmo.Value
				ammoBar.Text = tostring(ammo).."/"..tostring(maxAmmo)
				ammoBar.UIGradient.Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.new(1, 0.733, 0.12)),
					ColorSequenceKeypoint.new(math.clamp(ammo/maxAmmo, 0, 0.999), Color3.new(1, 0.733, 0.12)),
					ColorSequenceKeypoint.new(math.clamp((ammo/maxAmmo)+0.001, 0.001, 1), Color3.new(0.4, 0.4, 0)),
					ColorSequenceKeypoint.new(1, Color3.new(0.4, 0.4, 0)),
				})
			end
			updateAmmo()
			ammoBar.Visible = true
			table.insert(ammoCons, curAmmo.Changed:Connect(updateAmmo))
		else
			ammoBar.Visible = false
		end
		
		label.TextTransparency = 0
		label.BackgroundTransparency = 0.5
		tool.Equipped:Fire(true)
		
		if tool:GetAttribute("CanBeDropped") then
			controls.Register("Drop", true, drop)
		else
			controls.Unregister("Drop")
		end
		
		for _, v in anims do
			v:Stop()
			v:Destroy()
		end
		
		local anim = (plr :: any).Character.Humanoid:LoadAnimation(tool.HoldAnimation)
		table.insert(anims, anim)
		anim:Play()
	else
		for _, v in anims do
			v:Stop()
			v:Destroy()
		end
		anims = {}
		for _, v in ammoCons do
			ammoBar.Visible = false
			v:Disconnect()
		end
		tool.Equipped:Fire(false)
		controls.Unregister("Drop")
		if isServer then
			(screenUi:FindFirstChild(tostring(tool:GetAttribute("Slot"))..tool.Name) :: Instance):Destroy()
		end
	end
end

local function invRemoved(child: Instance)
	equip(false, child, nil, nil)
	local but = screenUi:FindFirstChild(tostring(child:GetAttribute("Slot"))..child.Name)
	if but then but:Destroy() end
	scriptCons.InventoryChangedEvent:Fire(child, false)
end

drop = function(name, state, object)
	for i, v in (plr :: any).Inventory:GetChildren() do
		if v:GetAttribute("Equipped") and v:GetAttribute("CanBeDropped") then
			invRemoved(v)
			ReplicatedStorage.ClientServer.DropWeapon:FireServer(v.Name)
		end
	end
end

local inv = plr:WaitForChild("Inventory")

for _, child in inv:GetChildren() do invAdded(child) end
inv.ChildAdded:Connect(invAdded)
inv.ChildRemoved:Connect(invRemoved)

local function selectItem(name: string)
	local num = tonumber(name:split(" ")[2])
	
	for _, child in screenUi:GetChildren() do
		if (child.ClassName == "TextButton") and (child.Name ~= "Sample") then
			local thisNum = tonumber(child.TextLabel.Text:sub(2, 2))
			if thisNum == num then
				equip(not child.Value.Value:GetAttribute("Equipped"), child.Value.Value, child)
				break
			end
		end
	end
end

for i=1, 9 do
	controls.Register("Slot "..tostring(i), false, selectItem)
end

-- Do a loop!
controls.Register("Next Weapon", false, function(name: string)
	local items = inv:GetChildren()
	local target = 0
	for _, v in items do
		if v:GetAttribute("Equipped") then
			target = v:GetAttribute("Slot")
			break
		end
	end
	
	local lowest, value = math.huge, nil
	for _, v in items do
		local slot = v:GetAttribute("Slot")
		if (slot) and ((slot > target) and (slot < lowest)) then
			lowest = slot
			value = slot
		end
	end
	
	if not value then
		lowest = target + 1
		target = 0
		for _, v in items do
			local slot = v:GetAttribute("Slot")
			if (slot) and ((slot > target) and (slot < lowest)) then
				lowest = slot
				value = slot
			end
		end
	end
	
	if not value then return end
	selectItem("Slot "..tostring(value))
end)

ReplicatedStorage.ServerClient.EquipWeapon.OnClientEvent:Connect(equip)
scriptCons:WaitForChild("RemoteEquipEvent").Event:Connect(equip)

game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)