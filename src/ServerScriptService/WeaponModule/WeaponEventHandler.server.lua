local RS = game:GetService("ReplicatedStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local cs = RS.ClientServer
local weaponModule = require(script.Parent)

local classesToKeep = {"WeldConstraint","Motor6D","Sound","Model","FileMesh","SpecialMesh"}
local function dropWeapon(plr,weapon)
	local char = plr.Character
	if not char then return end
	local hum = plr.Character.Humanoid
	local invW = plr.Inventory:FindFirstChild(weapon)
	if invW then
		if invW:GetAttribute("CanBeDropped") then
			plr.Inventory:FindFirstChild(weapon):Destroy()

			local model = RS.Items:FindFirstChild(weapon):FindFirstChildOfClass("Model"):Clone()
			for i,v: Instance in model:GetDescendants() do
				if not (v:IsA("BasePart") or table.find(classesToKeep,v.ClassName)) then
					v:Destroy()
				end
				if v:IsA("BasePart") then
					v.CanCollide = true
					v.CanTouch = true
				end
			end

			model.Name = weapon
			model:SetPrimaryPartCFrame(char.Head.CFrame + (char.Head.CFrame.LookVector*5))
			model.Parent = workspace["__Map"].WeaponSpawns
			model.PrimaryPart.AssemblyLinearVelocity = hum.MoveDirection * hum.WalkSpeed
		end
	end
end

RS.ClientServer.FireWeapon.OnServerEvent:Connect(function(plr,weapon,ray,position)
	if not plr.Character then return end
	local config = weapon:FindFirstChild("Configuration")
	if not config then return end
	if not plr.Character:FindFirstChild("Humanoid") then return end
	
	local curAmmo,lastFireTime = weapon:FindFirstChild("CurrentAmmo"),weapon:FindFirstChild("LastFireTime")
	local reloading,ammo,fireTime
	if weapon:FindFirstChild("Reloading") then reloading = weapon:FindFirstChild("Reloading").Value end
	if curAmmo then ammo = (curAmmo.Value <= 0) end
	if lastFireTime then
		fireTime = (lastFireTime.Value +
			config.OnUsed:GetAttribute("Firerate") > workspace:GetServerTimeNow()) end
	
	
	if 
		reloading or
		ammo or
		fireTime or
		(config.Aim:GetAttribute("ScopeRequired") and not plr:GetAttribute("Aim")) or
		plr.Character.Humanoid.Health <= 0 or
		not weapon:FindFirstAncestor(plr.Name) or
		
		not ReplicatedStorage.Items:FindFirstChild(weapon.Name) or
		not (weapon:GetAttribute("Weapon") or weapon:GetAttribute("Tool"))
	then 
		print(reloading, --in process of reloading
			ammo, --not enough ammo
			fireTime, --shooting too fast
			(config.Aim:GetAttribute("ScopeRequired") and not plr:GetAttribute("Aim")), --No scope with scope required
			plr.Character.Humanoid.Health <= 0, --player is dead
			not weapon:FindFirstAncestor(plr.Name), --weapon is not parented to player **NEEDS TWEAKING**
			not ReplicatedStorage.Items:FindFirstChild(weapon.Name), --weapon does not exist, maybe ban if this is triggered
			not (weapon:GetAttribute("Weapon") or weapon:GetAttribute("Tool")) --not a weapon/tool
		)
		return 
	end
	
	if curAmmo then weapon.CurrentAmmo.Value -= 1 end
	if lastFireTime then lastFireTime.Value = workspace:GetServerTimeNow() end
	
	if weapon:GetAttribute("Weapon") then
		for i=1,weapon.Configuration.Proj:GetAttribute("Amount") do
			weaponModule.SpawnProjectile(plr,weapon,ray,position)
		end
	else
		if not workspace:FindFirstChild("__Map") then return end
		if not workspace["__Map"]:FindFirstChild("Props") then return end
		weaponModule.PlaceTool(plr,weapon,ray,position)
	end
end)

RS.ClientServer.AimWeapon.OnServerEvent:Connect(function(plr,aim)
	plr:SetAttribute("Aim",aim)
end)


cs.DropWeapon.OnServerEvent:Connect(dropWeapon)

local dropEvent = script.Parent:FindFirstChild("DropWeapon")
dropEvent.Event:Connect(dropWeapon)

local neckC0 = CFrame.new(0, 0.8, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1);
local waistC0 = CFrame.new(0, 0.2, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1);
local rShoulderC0 = CFrame.new(1, 0.5, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1);
local lShoulderC0 = CFrame.new(-1, 0.5, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1);

cs.AttachWeapon.OnServerEvent:Connect(function(plr,weapon,equip)
	if not plr.Character then return end
	for _,v in plr.Character:GetChildren() do
		if v.ClassName == "Model" then
			v:Destroy()
		end
	end
	if equip and weapon then
		weapon = weapon:Clone()

		for i,v: Instance in weapon:GetDescendants() do
			if not (v:IsA("BasePart") or table.find(classesToKeep,v.ClassName) or v.Name == "LaserPos") then
				v:Destroy()
			end
		end
		
		local joint = Instance.new("Motor6D")
		joint.Part0 = plr.Character.RightHand
		joint.Part1 = weapon.Handle
		joint.Parent = weapon.Handle
		weapon.Parent = plr.Character
	end
end)

local rotateEvent = cs.RotateHead

rotateEvent.OnServerEvent:Connect(function(plr,theta)
	local char = plr.Character
	if char then
		local ut = char:FindFirstChild("UpperTorso")
		local head = char:FindFirstChild("Head")
		if head and ut then
			local tJoint = head:FindFirstChild("TiltJoint")
			if tJoint then
				tJoint.DesiredAngle = theta
			else
				tJoint = ServerStorage.DefaultPlayer.TiltJoint:Clone()
				tJoint.Part0 = head
				local tPart = head:FindFirstChild("TiltPart")
				if not tPart then
					tPart = ServerStorage.DefaultPlayer.TiltPart:Clone()
					tPart.Parent = head
				end
				tJoint.Part1 = tPart
				tJoint.Parent = head
			end
			
			local neck = head:FindFirstChild("Neck");
			local waist = char.UpperTorso:FindFirstChild("Waist");
			local rShoulder = char.RightUpperArm:FindFirstChild("RightShoulder");
			local lShoulder = char.LeftUpperArm:FindFirstChild("LeftShoulder");
			
			if neck and waist and rShoulder and lShoulder then
			
				local theta2 = tJoint.CurrentAngle
				neck.C0 = neckC0 * CFrame.fromEulerAnglesYXZ(theta2*0.5, 0, 0);
				waist.C0 = waistC0 * CFrame.fromEulerAnglesYXZ(theta2*0.5, 0, 0);
				rShoulder.C0 = rShoulderC0 * CFrame.fromEulerAnglesYXZ(theta2*0.5, 0, 0);
				lShoulder.C0 = lShoulderC0 * CFrame.fromEulerAnglesYXZ(theta2*0.5, 0, 0);
				
			end
		end
	end
end)

type InvWeapon = Model --saves me a headache
local reloadTable = {}
cs.ReloadWeapon.OnServerEvent:Connect(function(plr:Player,weapon:InvWeapon)
	if table.find(reloadTable,plr) then return end
	local char = plr.Character
	if char then
		local charWeapon: Model
		for _,v in char:GetChildren() do
			if v:IsA("Model") and v:GetAttribute("Weapon") and v.Name == weapon.Name then
				charWeapon = v
				break
			end
		end
		
		if charWeapon then
			local config = weapon:FindFirstChild("Configuration")
			local reloading = weapon:FindFirstChild("Reloading")
			local curAmmo = weapon:FindFirstChild("CurrentAmmo")
			if config and curAmmo then
				local reload = config:FindFirstChild("Reload")
				if reload then
					if reload:GetAttribute("AllowReload") then
						local magCapacity = reload:GetAttribute("MagCapacity")
						if magCapacity then
							if curAmmo.Value < magCapacity then
								reloading.Value = true
								table.insert(reloadTable,plr)
								local con
								local cancel
								con = charWeapon.Destroying:Connect(function()
									cancel = true
									table.remove(reloadTable,table.find(reloadTable,plr))
									con:Disconnect()
								end)
								
								local reloadSound = (charWeapon :: any):FindFirstChildOfClass("Model").PrimaryPart:FindFirstChild("Reload")
								if reloadSound then
									reloadSound:Play()
								end
								
								delay(reload:GetAttribute("Time"),function()
									if not cancel then
										curAmmo.Value = magCapacity
										table.remove(reloadTable,table.find(reloadTable,plr))
										reloading.Value = false
									end
								end)
							end
						end
					end
				end
			end
		end
	end
end)