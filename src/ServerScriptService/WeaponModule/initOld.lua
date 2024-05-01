--!nolint
--!nocheck

local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TS = game:GetService("TweenService")
local SSS = game:GetService("ServerScriptService")
local SS = game:GetService("ServerStorage")
local ServerStorage = game:GetService("ServerStorage")

local RoundHandlerTypes = require(ReplicatedFirst.RoundHandlerTypes)
local RoundHandler = require(SSS.RoundHandler.RoundHandler)

local getProfile: BindableFunction = SSS.PlayerSetup.GetProfile
local setProfile: BindableEvent = SSS.PlayerSetup.UpdateProfile

--constants
local directDamageTime = 30
local indirectDamageTime = 10

local module = {}

local function isCorrectDamage(plr1: Player, plr2: Player, checkSDorFreeKill: boolean): boolean
	if plr1:IsA("Player") and plr2:IsA("Player") then
		local round = RoundHandler.GetRound(SS:GetAttribute("RoundID"))
		
		if round then
			local roles = round.Gamemode.Roles
			
			local plr1Role = round:GetRole(plr1.Name, false)
			local plr2Role = round:GetRole(plr2.Name, false)
			
			local p1Val = round:GetPlayerValue(plr1.Name)
			if p1Val then
				local p2Val = round:GetPlayerValue(plr2.Name)
				if p2Val:GetAttribute("FreeKill") then return true end
				for _, v in p1Val.SelfDefenseList:GetChildren() do
					if v.Name == plr2.Name then
						if v.Value > workspace:GetServerTimeNow() then
							return true
						end
					end
				end
			end
			
			if table.find(roles[plr1Role].Allies, plr2Role) then
				return false --bad damage, lose karma or whatever
			else
				return true
			end
		end
	end
	return true
end

local flash = ReplicatedStorage.ServerClient.Flashbang
local function flashem(victim)
	if victim then flash:FireClient(victim) end
end

local function onDamage(assailant: Player?, victim: Player, damage: number, damageSource: string?, applyKarma: boolean, trueHealth: number?, part: BasePart?)
	local roundId = ServerStorage:GetAttribute("RoundID")
	if not roundId then return end

	local round: RoundHandlerTypes.Round = RoundHandler.GetRound(roundId)
	local vChar = victim.Character
	if victim and damage and round:IsRoundInProgress() and vChar then

		local vHum = vChar:FindFirstChildOfClass("Humanoid")
		local vHumHealth = trueHealth or vHum.Health
		local aVal
		if assailant then aVal = round:GetPlayerValue(assailant.Name) end
		local vVal = round:GetPlayerValue(victim.Name)

		if aVal and assailant then
			local aSD = false --attacker is acting in self-defense
			for _, v: NumberValue in aVal:FindFirstChild("SelfDefenseList"):GetChildren() do
				if v.Name == victim.Name and workspace:GetServerTimeNow() < v.Value then --Attacker is acting in self-defense
					aSD = true
					if vHum and vVal then
						vVal:SetAttribute("KilledInSelfDefense", vHumHealth <= 0)
					end
					break
				end
			end
			
			if damageSource ~= "Accident" and assailant ~= victim then
				if not aSD then
					for _, v: NumberValue in vVal:FindFirstChild("SelfDefenseList"):GetChildren() do
						if v.Value >= workspace:GetServerTimeNow() then --Remove old self-defense listings
							v:Destroy()
						end
					end

					local addTime = 20
					if damageSource == "Explosion" or "Weapon" then
						addTime = directDamageTime
					elseif damageSource == "Push" then
						addTime = indirectDamageTime
					end

					local val = Instance.new("NumberValue")
					val.Value = workspace:GetServerTimeNow()+addTime

					val.Name = assailant.Name
					val.Parent = vVal:FindFirstChild("SelfDefenseList")
				end
				
				local correctDmg = isCorrectDamage(assailant, victim, false)
				if correctDmg then
					if applyKarma then
						setProfile:Fire(assailant, "Karma", math.clamp(getProfile:Invoke(assailant).Karma+(damage/2), 1, 1000))
					end
				elseif not aSD then
					if vHum then
						if vHumHealth <= 0 then
							aVal:SetAttribute("FreeKill", true)
							aVal:SetAttribute("FreeKillReason", "RandomKill")
							aVal:SetAttribute("RandomKills", aVal:GetAttribute("RandomKills")+1)
						end
					end
					if applyKarma then
						setProfile:Fire(assailant, "Karma", math.clamp(getProfile:Invoke(assailant).Karma-damage, 1, 1000))
					end
				end
			end
		end
		
		if vHumHealth <= 0 then
			vVal:SetAttribute("MurderWeapon", damageSource)
			if part and part.Name == "Head" then vVal:SetAttribute("Headshot", true) end
			if damageSource == "__!!Explosion" then damageSource = "Explosion"
			else damageSource = "Weapon" end
			vVal:SetAttribute("DeathType", damageSource)
			
			if assailant then
				local killListVal = Instance.new("BoolValue")
				killListVal.Name = victim.Name
				killListVal.Value = true
				killListVal.Parent = aVal.KillList
			end
		end
	end
end

local function calculateDamage(shooter: Player?, part: BasePart, damageData: {any}, explosivePosition: Vector3?)
	local sChar, sKarma = nil, 0
	if shooter then
		sChar = shooter.Character
		sKarma = getProfile:Invoke(shooter).Karma
	end
	if damageData and part then
		local dmg = damageData
		if dmg then
			local falloffStart = dmg["FalloffStart"]
			local falloffEnd = dmg["FalloffEnd"]
			local falloffMult = dmg["Falloff"]
			
			local pName = part.Name
			local body = "Base"
			if pName == "Head" then
				body = "Head"
			elseif pName:match("Foot") or pName:match("Leg") or pName:match("Hand") or pName:match("Arm") then
				body = "Limb"
			elseif pName:match("Torso") or (pName == "HumanoidRootPart") then
				body = "Base"
			end
			
			local baseDmg = dmg[body] or dmg["Base"] or 0
			
			if baseDmg then
				local falloffDmg:number
				local dist: number = 0
				if explosivePosition then
					dist = (explosivePosition - part.Position).Magnitude
				elseif sChar then
					assert(sChar.PrimaryPart)
					dist = (sChar.PrimaryPart.Position - part.Position).Magnitude
				end
				
				if falloffStart and falloffEnd and falloffMult then
					if dist >= falloffStart and dist < falloffEnd then
						falloffMult = require(game.ReplicatedFirst.API).LerpNumber(1, falloffMult, (dist-falloffStart)/falloffEnd)
					elseif dist <= falloffStart then 
						falloffMult = 1
					end
				end
				
				falloffDmg = baseDmg*falloffMult
				return falloffDmg * (sKarma/1000)
			end
		end
	end
	return
end

function module.CreateExplosion(assailant: Player?, position: Vector3, radius: number, damageData:{["FalloffStart"]:number, ["FalloffEnd"]:number, ["Falloff"]:number, ["Base"]:number}, force: number, flashbang: boolean?)
	local explosion = Instance.new("Explosion")
	explosion.BlastRadius = radius
	explosion.BlastPressure = force
	explosion.ExplosionType = Enum.ExplosionType.NoCraters
	explosion.DestroyJointRadiusPercent = 0
	explosion.Position = position
	explosion.Parent = (workspace :: any).Proj.ImpactHoles

	local soundPart = Instance.new("Part")
	soundPart.Name = "ExplosionSoundPart"
	soundPart.Transparency = 1
	soundPart.CanTouch = false
	soundPart.CanCollide = false
	soundPart.CanQuery = false
	soundPart.Anchored = true
	soundPart.Position = position
	soundPart.CastShadow = false
	soundPart.Size = Vector3.zero
	soundPart.Color = Color3.new(0, 0, 0)
	soundPart.Parent = (workspace :: any).Proj.ImpactHoles
	local sound = ServerStorage.Explosion:Clone()
	sound.Parent = soundPart
	sound:Play()
	sound.Ended:Connect(function()
		soundPart:Destroy()
	end)

	local filter = {workspace:FindFirstChild("__Map"):FindFirstChild("Props")}
	for _, v in Players:GetPlayers() do
		local char = v.Character
		if char then
			local hum = char:FindFirstChild("Humanoid")
			if hum then
				if hum.Health > 0 then
					table.insert(filter, char)
				end
			end
		end
	end

	local params = OverlapParams.new()
	params.RespectCanCollide = false
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = filter
	local hitParts = workspace:GetPartBoundsInRadius(position, radius, params)

	local hitHums = {} -- hrp: hum
	for _, v in hitParts do
		local root = v.Parent:FindFirstChild("HumanoidRootPart")
		if v:FindFirstAncestor("Props") then
			root = v:FindFirstAncestorWhichIsA("BasePart") or v
		end
		if not root or hitHums[root] then
			continue
		end
		local hum = v.Parent:FindFirstChild("Humanoid")
		if (not hum) or (v:FindFirstAncestor("Props") and flashbang) then
			continue
		end
		hitHums[root] = hum
	end

	for root, hum in hitHums do
		if hum.Health <= 0 then
			continue
		end
		if flashbang and Players:GetPlayerFromCharacter(hum.Parent) then
			flashem(Players:GetPlayerFromCharacter(hum.Parent))
		else
			local damage = calculateDamage(assailant, root, damageData, position) or 0
			local trueHealth = hum.Health - damage
			if hum:FindFirstAncestor("Props") then
				hum.Health = trueHealth
				if trueHealth < 0 then
					local onBreak = hum.Parent:FindFirstChild("OnBreak", true)
					if onBreak then require(onBreak)(assailant) end
					hum.Parent:Destroy()
				end
			else
				local round = RoundHandler.GetRound(SS:GetAttribute("RoundID"))
				--prioritise OnDeath, in doing so: pass a trueHealth argument to onDamage, run OnDeath before taking damage, and set OverrideDeathLogic
				onDamage(assailant, Players:GetPlayerFromCharacter(hum.Parent), damage, "__!!Explosion", true, trueHealth)
				if trueHealth < 0 and round.RoundPhase == "Playing" then
					round:OnDeath(hum)
					hum:SetStateEnabled(Enum.HumanoidStateType.Freefall, true)
					hum:SetAttribute("OverrideDeathLogic", true)

					hum.AutoRotate = false
					for i2, v2 in hum.Parent:GetDescendants() do
						if v2:IsA("BasePart") then
							v2:SetNetworkOwner()
						end
					end

					local dir = -(position - root.Position).Unit
					if root then
						root.CanCollide = false
						root.CanQuery = false
						root.CanTouch = false
						root:ApplyImpulse(dir*force*root.AssemblyMass)
					else
						root:ApplyImpulse(dir*force*root.AssemblyMass)
					end
				end
				hum:TakeDamage(damage)
			end
		end
	end
end

function module.SpawnProjectile(shooter, weapon, rayinfo, position)
	local humanoid = shooter.Character.Humanoid
	local rand = Random.new()
	
	local serverWeapon = ReplicatedStorage.Items:FindFirstChild(weapon.Name)
	if not serverWeapon then --[[ban plr]] end
	
	local configS = serverWeapon.Configuration
	
	local projType = configS.Proj:GetAttribute("Type")
	local proj
	
	if projType ~= "None" then
		proj = (ServerStorage.Projectiles[projType] :: any):Clone()
		proj.CollisionGroup = "WeaponProjectiles"
	end

	local spreadVal
	if humanoid.Jump or humanoid:GetState() == Enum.HumanoidStateType.Freefall then
		spreadVal = configS.Proj:GetAttribute("SpreadFalling")*100
	elseif humanoid.MoveDirection:Dot(humanoid.MoveDirection) > 0 then
		spreadVal = configS.Proj:GetAttribute("SpreadMoving")*100
	else
		spreadVal = configS.Proj:GetAttribute("Spread")*100
	end
	local spread = Vector3.new(rand:NextNumber(-spreadVal, spreadVal)/100, rand:NextNumber(-spreadVal, spreadVal)/100, rand:NextNumber(-spreadVal, spreadVal)/100)

	local char = shooter.Character
	local charWeapon = char:FindFirstChild(weapon.Name)
	
	if weapon:FindFirstChild("Model") then
		weapon.Model.PrimaryPart.Fired:Play()
		local firedSound = weapon.Model.PrimaryPart.Fired:Clone()
		firedSound.PlayOnRemove = true
		firedSound.Parent = charWeapon.Model.PrimaryPart
		firedSound:Destroy()
		local mzl = weapon.Model.PrimaryPart:FindFirstChild("MuzzleFlash")
		if mzl then
			mzl.Enabled = true
			task.delay(0.1, function()
				if weapon then if weapon:FindFirstChildOfClass("Model") then weapon:FindFirstChildOfClass("Model").PrimaryPart.MuzzleFlash.Enabled = false end end
			end)
		end
	end

	if (char.PrimaryPart.Position-position).Magnitude > 14 then --shooting too far away from yourself is odd
		position = char.Head.Position
	end
	
	if configS.General:GetAttribute("Type") == "Grenade" then
		proj.Position = position
		proj.Parent = (workspace :: any).Proj.Proj
		proj.AssemblyLinearVelocity = rayinfo.Unit.Direction*configS.Proj:GetAttribute("SpeedGrenade")/2
		task.delay(4, function()
			if (not proj) or (not proj.Parent) then
				return -- i.e, grenade was disarmed by shooting it
			end
			module.CreateExplosion(shooter, proj.Position, configS.Damage.Uniques:GetAttribute("ExplosRadius"), configS.Damage:GetAttributes(), configS.Damage.Uniques:GetAttribute("ExplosPressure"), serverWeapon.Name=="Flashbang")
			proj:Destroy()
		end)
	else
		local rayParams = RaycastParams.new()
		rayParams.FilterDescendantsInstances = {char, (workspace:FindFirstChild("Proj") :: any):FindFirstChild("ImpactHoles"), workspace:FindFirstChild("__Map"):FindFirstChild("Bounds")}
		rayParams.FilterType = Enum.RaycastFilterType.Exclude
		rayParams.CollisionGroup = "WeaponProjectiles"
		rayParams.IgnoreWater = true

		local rayResult
		local endPos
		local dir = rayinfo.Direction*configS.Proj:GetAttribute("MaxDistance")+spread
		local dirAim = rayinfo.Unit.Direction*configS.Proj:GetAttribute("MaxDistance")+(spread*configS.Aim:GetAttribute("SpreadMult"))
		if shooter:GetAttribute("Aim") then
			rayResult = workspace:Raycast(char.Head.Position, dirAim, rayParams)
			endPos = rayResult and rayResult.Position or dirAim*configS.Proj:GetAttribute("MaxDistance")
			if proj then
				proj.CFrame = CFrame.lookAt(char.Head.Position, endPos)
			end
		else
			rayResult = workspace:Raycast(position, dir, rayParams)
			endPos = rayResult and rayResult.Position or dir*configS.Proj:GetAttribute("MaxDistance")
			if proj then
				proj.CFrame = CFrame.lookAt(char.Head.Position, endPos)
			end
		end
		
		if proj then
			endPos = proj.Position + (proj.CFrame.LookVector * configS.Proj:GetAttribute("MaxDistance"))
			if rayResult then
				endPos = rayResult.Position
			end
			
			local tween = TS:Create(proj, TweenInfo.new(((char.Head.Position-endPos).Magnitude)/configS.Proj:GetAttribute("Speed")), {Position = endPos})
			tween:Play()
			tween.Completed:Once(function()
				proj:Destroy()
			end)
			proj.Parent = (workspace :: any).Proj.Proj
		end
		
		if rayResult then
			if weapon:FindFirstChildOfClass("Model") then
				module.OnHit(rayResult.Instance, serverWeapon, shooter, (rayResult.Position-weapon:FindFirstChildOfClass("Model").PrimaryPart.Position).Magnitude, rayResult, rayinfo)
			end	
		end
	end
	--TODO: single use should be changed to MaxUses
	if configS.General:GetAttribute("SingleUse") then
		ReplicatedStorage.ServerClient.EquipWeapon:FireClient(shooter, false, weapon, nil, true)
		shooter.Inventory:FindFirstChild(weapon.Name):Destroy()
	end
end

function module.CreateBulletHole(part, position, colour, rayResult)
	local impactHole = Instance.new("Part")
	impactHole.Anchored = false
	impactHole.Transparency = 1
	impactHole.Size = Vector3.new(0.5, 0.5, 0.1)
	impactHole.CFrame = CFrame.lookAt(rayResult.Position, rayResult.Position + rayResult.Normal)
	
	impactHole.CanCollide = false
	impactHole.CanTouch = false
	impactHole.CanQuery = false
	
	local impactDecal = Instance.new("Decal")
	impactDecal.Texture = "rbxassetid://130624105"
	impactDecal.Color3 = colour
	impactDecal.Parent = impactHole
	
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = rayResult.Instance
	weld.Part1 = impactHole
	weld.Parent = rayResult.Instance
	
	delay(5, function()
		TS:Create(impactDecal, TweenInfo.new(5), {Transparency = 1}):Play()
		delay(5, function()
			weld:Destroy()
			impactHole:Destroy()
			impactHole = nil
			impactDecal = nil
			weld = nil
		end)
	end)
	
	impactHole.Parent = part
end

function module.OnHit(part, weapon, shooter, distance, rayResult, rayInfo)
	local model = part:FindFirstAncestorOfClass("Model")
	if model then
		local humanoid: Humanoid = model:FindFirstChildOfClass("Humanoid")
		if humanoid then
			local plr = Players:GetPlayerFromCharacter(model)
			local damage = calculateDamage(shooter, part, weapon.Configuration.Damage:GetAttributes()) or 0
			local doDamage = true
			
			if humanoid then
				if humanoid.Health <= 0 then return end
			end
			
			local skip = false
			if not plr then skip = true end
			if not skip then
				local round = RoundHandler.GetRound(SS:GetAttribute("RoundID"))
				if not round then skip = true end
				local val = round:GetPlayerValue(plr.Name)
				if not val then skip = true end
				local mods = val:FindFirstChild("Modifiers")
				if not mods then skip = true end
				if not skip then
					for i, v in val.Modifiers:GetAttributes() do
						local split = string.split(i, "_")
						if split[1] ~= "AbsorbDamage" then continue end
						for _, v2 in string.split(split[2], "0") do
							if not string.match(part.Name, v2) then continue end
							mods:SetAttribute(i, v-damage)
							doDamage = false
							if mods:GetAttribute(i) <= 0 then mods:SetAttribute(i) end
							break
						end
					end
				end
			end
				
			if not model:FindFirstChildOfClass("ForceField") then
				local damageVictim = true
				local damageShooter = false
				if doDamage then
					if weapon:FindFirstChildOfClass("Model").PrimaryPart:FindFirstChild("HitFlesh") then shooter.Character:FindFirstChildOfClass("Model"):FindFirstChildOfClass("Model").PrimaryPart.HitFlesh:Play() end
					if plr then
						if weapon.Configuration.Damage:GetAttribute("PunishmentProtectsVictim") then
							damageVictim = isCorrectDamage(shooter, plr, true)
						end
						if weapon.Configuration.Damage:GetAttribute("PunishWrongDamage") then
							damageShooter = not isCorrectDamage(shooter, plr, true)
						end
					end
					if damageVictim then
						humanoid:TakeDamage(damage)
					end
					if damageShooter then
						shooter.Character.Humanoid:TakeDamage(damage)
					end
					if humanoid.Health <= 0 then
						humanoid:SetStateEnabled(Enum.HumanoidStateType.Freefall, true)
						for i, v in model:GetDescendants() do
							if v:IsA("BasePart") and not v.Anchored then
								v:SetNetworkOwner()
							end
						end
						local root = model:FindFirstChild("HumanoidRootPart")
						if part.Name:match("Head") or weapon.Configuration.General:GetAttribute("SilentDeath") then
							if root then
								local death = root:FindFirstChild("Death")
								if death then death.Volume = 0 end
							end
						end
						
						if root then
							root:ApplyImpulse(rayInfo.Unit.Direction*weapon.Configuration.Proj:GetAttribute("Speed")/2*part.AssemblyMass)
						end
						
						if part:FindFirstAncestor("Props") then
							local onBreak = part.Parent:FindFirstChild("OnBreak", true)
							if onBreak then require(onBreak)(shooter) end
							part.Parent:Destroy()
						end
					end
				end
				if plr then
					onDamage(shooter, plr, damage, weapon.Name, damageVictim, nil, part)
				end
			end
			--onDamage is called here, regardless of doDamage, because self defense and such should still apply, even if no damage is dealt
		end
	elseif part:IsDescendantOf((workspace:FindFirstChild("Proj") :: any):FindFirstChild("Proj")) then
		for _, v in (workspace:FindFirstChild("Proj") :: any):FindFirstChild("Proj"):GetChildren() do
			if v:IsAncestorOf(part) then
				v:Destroy()
				return
			end
		end
	end
	module.CreateBulletHole(part, part.Position, part.Color, rayResult)
	return true
end

function module.PlaceTool(plr, tool, ray, pos)
	local serverTool = ReplicatedStorage.Items:FindFirstChild(tool.Name)
	if not serverTool then --[[ban plr]] end

	local configS = serverTool.Configuration
	if configS.General:GetAttribute("SingleUse") then
		ReplicatedStorage.ServerClient.EquipWeapon:FireClient(plr, false, tool, nil, true)
		plr.Inventory:FindFirstChild(tool.Name):Destroy()
	end
	
	local props = workspace:FindFirstChild("__Map"):FindFirstChild("Props")
	if not props then return end
	
	local prop = serverTool:FindFirstChildOfClass("Model"):Clone()
	local part = prop.PrimaryPart
	for _, v in part:GetChildren() do
		if v:IsA("Script") then
			v.Enabled = true
		else
			v:Destroy()
		end
	end
	part.CanCollide = true
	part.CanTouch = true
	part.CanQuery = true
	local hum = Instance.new("Humanoid")
	hum.MaxHealth = configS.General:GetAttribute("PropHealth")
	hum.Health = hum.MaxHealth
	hum.Parent = prop
	
	local toolData = Instance.new("Folder")
	for i, v in configS.ToolUsed:GetAttributes() do
		toolData:SetAttribute(i, v)
	end
	for i, v in configS.ToolData:GetAttributes() do
		local class = ""
		if typeof(v) == "string" then class = "StringValue" elseif typeof(v) == "number" then class = "IntValue" end
		local val = Instance.new(class)
		val.Name = i
		val.Value = v
		val.Parent = toolData
	end
	
	toolData.Name = "ToolData"
	toolData.Parent = prop
	prop:PivotTo(CFrame.new(pos))
	prop.Name = "Equipment_"..tool.Name
	prop.Parent = props
end


return module