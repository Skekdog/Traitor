local TS = game:GetService("TweenService")
local CAS = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")

local plr = Players.LocalPlayer
local controls = require(ReplicatedFirst.ControlManager)
local ui = require(ReplicatedFirst.UIManager)
plr:WaitForChild("Inventory")

local spring = require(game.ReplicatedStorage.spring)
local isAiming = false

local camera = game.Workspace.CurrentCamera
local humanoid = script.Parent:WaitForChild("Humanoid")

local viewModel = game.ReplicatedStorage:WaitForChild("ViewModel"):Clone()

local reloadSpring = spring.new(Vector3.zero,Vector3.zero,Vector3.zero,7,0.8)
local breatheSpring = spring.new(Vector3.zero,Vector3.zero,Vector3.zero,1,10)
local recoilSpring = spring.new(Vector3.zero,Vector3.zero,Vector3.zero,30,0.8)
local swaySpring = spring.new(Vector3.zero,Vector3.zero,Vector3.zero,15,1)
local bobSpring = spring.new(Vector3.zero,Vector3.zero,Vector3.zero,10,1)

local recoilMod = 3

local function createLaser(genConfig,model)
	local laser: Part
	local weld = Instance.new("WeldConstraint")
	laser = Instance.new("Part")

	local mesh = Instance.new("SpecialMesh")
	mesh.MeshId = "rbxassetid://9788624116"
	mesh.Scale = Vector3.new(0.2,0.2,1000)
	mesh.Parent = laser

	laser.CastShadow = false
	laser.Material = Enum.Material.Neon
	laser.Color = genConfig:GetAttribute("LaserColour")
	laser.Transparency = 0.6

	local laserAttach = model:FindFirstChildOfClass("Model").PrimaryPart.LaserPos
	local worldPos = laserAttach.WorldPosition

	laser.Size = Vector3.new(0.2,0.2,1000)
	laser.Orientation = model.Handle.Orientation
	laser.Position = worldPos

	laser.Anchored = false
	laser.CanCollide = false
	laser.CanTouch = false
	laser.CanQuery = false

	weld.Part1 = model:FindFirstChildOfClass("Model").PrimaryPart
	weld.Part0 = laser

	laser.Name = "__!!LaserPart"
	weld.Name = "__!!LaserWeld"
	weld.Parent = model
	laser.Parent = model
	
	local ball = Instance.new("Part")
	
	ball.CastShadow = false
	ball.Transparency = 0.2
	ball.Material = Enum.Material.Neon
	ball.Color = genConfig:GetAttribute("LaserColour")
	ball.Shape = Enum.PartType.Ball
	
	ball.TopSurface = Enum.SurfaceType.Smooth
	ball.BottomSurface = Enum.SurfaceType.Smooth
	ball.LeftSurface = Enum.SurfaceType.Smooth
	ball.RightSurface = Enum.SurfaceType.Smooth
	ball.FrontSurface = Enum.SurfaceType.Smooth
	ball.BackSurface = Enum.SurfaceType.Smooth
	
	ball.Size = Vector3.new(1.75,1.75,1.75)
	
	ball.Anchored = true
	ball.CanCollide = false
	ball.CanTouch = false
	ball.CanQuery = false
	
	ball.Name = "__!!LaserBall"
	
	return laser,ball
end

local function onUpdate(dt)
	local child = script.Parent:FindFirstChildOfClass("Model")
	
	if child and (not child:GetAttribute("Weapon") and not child:GetAttribute("Tool")) then
		child = nil
		return
	end
	
	local moveDirection = humanoid.MoveDirection
	local isMoving = moveDirection:Dot(moveDirection) > 0
	
	bobSpring.target = Vector3.new(math.sin(workspace:GetServerTimeNow()*7)*0.1, math.sin(workspace:GetServerTimeNow()*10)*0.1, 0)
	
	if isMoving then
		bobSpring:update(dt)
	else
		bobSpring.target = Vector3.zero
		bobSpring:update(dt)
	end
	
	if isAiming then
		breatheSpring.target = Vector3.new(math.cos(workspace:GetServerTimeNow())/8, math.cos(workspace:GetServerTimeNow())/4, math.cos(workspace:GetServerTimeNow())/8)/5
	else
		breatheSpring.target = Vector3.new(math.cos(workspace:GetServerTimeNow())/2, math.cos(workspace:GetServerTimeNow()), math.cos(workspace:GetServerTimeNow())/2)/5
	end
	breatheSpring:update(dt)

	swaySpring:update(dt)
	recoilSpring:update(dt)
	reloadSpring:update(dt)
	
	if joint and child and viewModel:FindFirstChild(child.Name) then
		local camWeapon = viewModel:FindFirstChild(child.Name)
		local invWeapon = plr.Inventory:FindFirstChild(child.Name)
		local genConfig = invWeapon.Configuration.General
		
		local ball,laser = camWeapon:FindFirstChild("__!!LaserBall"),camWeapon:FindFirstChild("__!!LaserPart")
		if ball then
			local worldPos:Vector3 = camWeapon:FindFirstChildOfClass("Model").PrimaryPart.LaserPos.WorldPosition
			local rayDir = camera:ViewportPointToRay(camera.ViewportSize.X/2,camera.ViewportSize.Y/2,1).Unit.Direction*invWeapon.Configuration.Proj:GetAttribute("MaxDistance")
			local raycast = workspace:Raycast(worldPos,rayDir)

			if raycast then
				local pos = raycast.Position
				local dist = raycast.Distance
				ball.Transparency = 0.2
				ball.Position = pos
				laser.Size = Vector3.new(0.2,0.2,dist/2)
				laser.Mesh.Scale = Vector3.new(0.2,0.2,dist/2)
				laser.Position = worldPos+(laser.CFrame.LookVector*dist/2)
			else
				ball.Transparency = 1
			end
		end
		
		local position = genConfig:GetAttribute("Position")
		local rotation = genConfig:GetAttribute("Rotation")
		joint.C0 = CFrame.new(position.X,position.Y,position.Z)*CFrame.Angles(rotation.X,rotation.Y,rotation.Z) * CFrame.new(bobSpring.p) * CFrame.new(breatheSpring.p) * CFrame.new(0, 0, recoilMod*recoilSpring.p.x) * CFrame.new(reloadSpring.p)
	end
	
	camera.CFrame = camera.CFrame * CFrame.fromEulerAnglesYXZ(recoilSpring.p.y, recoilSpring.p.z, 0)
	viewModel.Head.CFrame = camera.CFrame * CFrame.Angles(swaySpring.p.y, swaySpring.p.x, 0)+(camera.CFrame.LookVector*0.5)
	
	updateArm("Right")
	updateArm("Left")
end

function updateArm(key)
	-- get shoulder we are rotating
	local shoulder = viewModel[key.."UpperArm"][key.."Shoulder"];
	-- calculate worldspace arm cframe from Right or Left part in the weapon model
	local cf = CFrame.new()
	if viewModel:FindFirstChildOfClass("Model") then
		cf = viewModel:FindFirstChildOfClass("Model")[key].CFrame * CFrame.Angles(math.pi/2, 0, 0) * CFrame.new(0, 1.5, 0)
	end
	-- update the C1 value needed to for the arm to be at cf (do this by rearranging the joint equality from before)
	shoulder.C1 = cf:inverse() * shoulder.Part0.CFrame * shoulder.C0;
end


CAS:BindAction("Sway",function(_,_,input)
	local delta = input.Delta
	local x,y = delta.x * 0.1, delta.y * 0.1
	swaySpring.target = Vector3.new(math.rad(x), math.rad(y), 0) -- this still needs some adjustment
end,false,Enum.UserInputType.MouseMovement)

Players.LocalPlayer.Inventory.ChildAdded:Connect(function(child)
	if child:IsA("Model") and (child:GetAttribute("Weapon") or child:GetAttribute("Tool")) then
		child:WaitForChild("Equipped").Event:Connect(function(equip)
			if equip then
				if child:FindFirstChild("Reloading") then
					child.Reloading.Changed:Connect(function(val)
						if val then
							reloadSpring.p = Vector3.new(10,5,10)
						else
							reloadSpring.p = Vector3.zero
						end
					end)
				end
				local config = child:FindFirstChild("Configuration")
				local genConfig = config:FindFirstChild("General")
				local aimConfig = config:FindFirstChild("Aim")
				task.wait() --idk why this is here and i dont feel like finding out
				local childClone = child:Clone()
				for i,v in pairs(viewModel:GetChildren()) do
					if v:IsA("Model") and v.Name ~= child.Name then
						if viewModel.Head:FindFirstChild(v.Name.."Motor6D") then viewModel.Head:FindFirstChild(v.Name.."Motor6D"):Destroy() end
						v:Destroy()
					end
				end

				childClone.Parent = viewModel
				viewModel.Parent = camera

				joint = Instance.new("Motor6D")
				local position = config.General:GetAttribute("Position")
				local rotation = config.General:GetAttribute("Rotation")
				joint.C0 = CFrame.new(position.X,position.Y,position.Z)*CFrame.Angles(rotation.X,rotation.Y,rotation.Z)
				joint.Part0 = viewModel.Head
				joint.Part1 = childClone.Handle
				joint.Name = child.Name.."Motor6D"
				joint.Parent = viewModel.Head
				
				if genConfig:GetAttribute("Laser") then
					local ball = createLaser(genConfig,childClone)
					local rayDir = camera:ViewportPointToRay(camera.ViewportSize.X/2,camera.ViewportSize.Y/2,1).Unit.Direction*config.Proj:GetAttribute("MaxDistance")
					local raycast = workspace:Raycast(childClone:FindFirstChildOfClass("Model").PrimaryPart.LaserPos.WorldPosition,rayDir)
					
					if raycast then
						ball.Position = raycast.Position
						ball.Transparency = 0.2
						ball.Parent = childClone
					end
				end
				
				local mb2Began
				local mb2Changed
				
				local aimCount = 0
				local offset
				if aimConfig:GetAttribute("Aim") then
					offset = child.Handle.CFrame:inverse() * child.AimPoint.CFrame
				end
				local isAiming = false
				local function aimDownSights(_, state, _, toggled)
					isAiming = not isAiming
					
					if not toggled then
						if state == Enum.UserInputState.Begin then
							isAiming = true
						elseif state == Enum.UserInputState.End then
							isAiming = false
						end
					end
					
					if plr.Character:FindFirstChild("Humanoid").Health <= 0 then
						isAiming = false
					end
						
					if aimConfig:GetAttribute("Scope") then
						UIS.MouseIconEnabled = not isAiming
						local scope = ui.GetUI("Scope", "UserTriggered")
						if scope then
							scope:ToggleVisible(isAiming)
							for _,v in scope.UI:GetDescendants() do
								if v.ClassName == "Frame" then
									TS:Create(v,TweenInfo.new(0.3),{BackgroundTransparency = isAiming and 0 or not isAiming and 1}):Play()
								elseif v.ClassName == "ImageLabel" then
									TS:Create(v,TweenInfo.new(0.3),{ImageTransparency = isAiming and 0 or not isAiming and 1}):Play()
								end
							end
						end
					end
					
					TS:Create(camera,TweenInfo.new(0.5),{FieldOfView = isAiming and aimConfig:GetAttribute("FOV") or 70}):Play()
					humanoid.WalkSpeed = isAiming and aimConfig:GetAttribute("Speed") or 16
					UIS.MouseDeltaSensitivity = isAiming and aimConfig:GetAttribute("Sensitivity") or 1
					
					if joint then
						if joint.Parent then
							if isAiming then
								bobSpring.target = Vector3.zero
							end

							local start = joint.C1
							local goal = isAiming and (joint.C0-bobSpring.p) * offset or CFrame.new() --society if the errors made sense

							aimCount = aimCount + 1;
							local current = aimCount;
							local co
							co = coroutine.create(function()
								for t = 0, 101, 10 do
									if (current ~= aimCount) then break end
									game:GetService("RunService").RenderStepped:Wait()
									if not joint then break end
									joint.C1 = start:Lerp(goal, t/100)
								end
								coroutine.yield(co)
								coroutine.close(co)
							end)
							coroutine.resume(co)
						end
					end

					ReplicatedStorage.ClientServer.AimWeapon:FireServer(isAiming)
				end
				
				if aimConfig:GetAttribute("Aim") then
					controls.Register("Alternate Fire", true, aimDownSights)
				end
				local fireCon
				fireCon = (game :: any):WaitForChild("ClientStorage"):WaitForChild("ScriptConnections").FireEvent.Event:Connect(function()
					-- recoilmod is used for physical recoil, man rewriting this will be nice
					local recoil = child.Configuration.OnUsed:GetAttribute("CameraRecoil")
					recoilMod = isAiming and child.Configuration.OnUsed:GetAttribute("PhysicalRecoil")/3 or child.Configuration.OnUsed:GetAttribute("PhysicalRecoil")
					recoilSpring.p = Vector3.new(recoil/13, math.rad(recoil), math.rad(math.random(-recoil, recoil)*0.1))
					task.wait(child.Configuration.OnUsed:GetAttribute("Firerate"))
				end)

				local unequipCon
				unequipCon = child.Equipped.Event:Connect(function(equip)
					if not equip then
						unequipCon:Disconnect()
						fireCon:Disconnect()
						
						if mb2Began then mb2Began:Disconnect() end
						if mb2Changed then mb2Changed:Disconnect() end
						
						controls.Unregister("Alternate Fire")
						
						mb2Began = nil
						mb2Changed = nil
						unequipCon = nil
						fireCon = nil
						
						if isAiming and aimConfig:GetAttribute("Aim") then aimDownSights() end
						if joint then joint:Destroy() end
						if childClone then childClone:Destroy() end

						joint = nil
						childClone = nil
					end
				end)
			end
		end)
	end
end)

local renderStepped
renderStepped = game:GetService("RunService").RenderStepped:Connect(onUpdate)

local function onDied()
	controls.Unregister("Alternate Fire")
	workspace.CurrentCamera.FieldOfView = 70
	if workspace.CurrentCamera:FindFirstChild("ViewModel") then (workspace :: any).CurrentCamera.ViewModel:Destroy() end
	local scope = ui.GetUI("Scope","UserTriggered")
	if scope then scope:ToggleVisible(false) end
	viewModel.Parent = nil
	viewModel:Destroy()
	renderStepped:Disconnect()
end

humanoid.Died:Connect(onDied)

while task.wait(0.01) do
	ReplicatedStorage.ClientServer.RotateHead:FireServer(math.asin(camera.CFrame.LookVector.y))
	if not renderStepped.Connected then
		break
	end
end