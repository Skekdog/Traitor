--!nocheck
local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TS = game:GetService("TweenService")

local plr = Players.LocalPlayer

local controls = require(ReplicatedFirst.ControlManager)
--local settingsManager = require(plr.PlayerScripts.SettingsManager)

local clientStorage = game:WaitForChild("ClientStorage")
local scriptCons = clientStorage:WaitForChild("ScriptConnections")

local function reloadFunc(tool, config)
	if tool.Parent == nil or tool.CurrentAmmo.Value == config.Reload:GetAttribute("MagCapacity") then
		task.wait()
		return
	end
	if config.Reload:GetAttribute("AllowReload") then
		local anim: AnimationTrack = plr.Character.Humanoid:LoadAnimation(tool.ReloadAnimation)
		anim:Play()
		local animCon
		animCon = anim.Stopped:Connect(function()
			anim:Destroy()
			animCon:Disconnect()
			animCon = nil
		end)
		ReplicatedStorage:WaitForChild("ClientServer").ReloadWeapon:FireServer(tool)
	end
	task.wait(config.Reload:GetAttribute("Time"))
	return true
end

--local ammoCon
scriptCons.EquipEvent.Event:Connect(function(tool, equip)
	if equip then
		local config = tool.Configuration
		local curAmmo = tool:FindFirstChild("CurrentAmmo")
		local lastFire = tool:FindFirstChild("LastFireTime")
		
		if config:FindFirstChild("Reload") and config.Reload:GetAttribute("AllowReload") then
			controls.Register("Reload Weapon", true, function()reloadFunc(tool, config)end)
		else
			controls.Unregister("Reload Weapon")
		end
		
		--all of this is function is garbage todo rewrite
		
		local function shoot(action, state, input)
			if state == Enum.UserInputState.Begin then
				repeat
					local reloadDisable = false
					if tool:FindFirstChild("Reloading") then
						reloadDisable = tool.Reloading.Value
					end
					local ammo
					if curAmmo then ammo = curAmmo.Value else ammo = 1 end
					if ammo >= 1 and not reloadDisable and tool.Parent then
						if config.Aim:GetAttribute("ScopeRequired") then
							if not plr:GetAttribute("Aim") then
								task.wait()
								continue
							end
						end
						repeat
							task.wait()
							if not config:FindFirstChild("OnUsed") then return end
						until lastFire.Value + config.OnUsed:GetAttribute("Firerate") < workspace:GetServerTimeNow() or not tool:GetAttribute("Equipped")
						if not tool:GetAttribute("Equipped") or input.UserInputState == Enum.UserInputState.End or input.UserInputState == Enum.UserInputState.Cancel then break end
						if not workspace.CurrentCamera:FindFirstChild("ViewModel") then return end
						local primaryPart = (workspace :: any).Camera.ViewModel:FindFirstChildOfClass("Model"):FindFirstChildOfClass("Model").PrimaryPart
						if curAmmo then ammo = curAmmo.Value else ammo = 1 end
						if primaryPart and ammo >= 1 then
							reloadDisable = false
							if tool:FindFirstChild("Reloading") then
								reloadDisable = tool.Reloading.Value
							end
							if not reloadDisable then
								scriptCons.FireEvent:Fire()
								ReplicatedStorage.ClientServer.FireWeapon:FireServer(tool,
									workspace.CurrentCamera:ViewportPointToRay(
										workspace.CurrentCamera.ViewportSize.X/2, workspace.CurrentCamera.ViewportSize.Y/2, 1),
									primaryPart.Position)

								lastFire.Value = workspace:GetServerTimeNow()
								if curAmmo then curAmmo.Value -= 1 end
								
								local flash = primaryPart:FindFirstChild("MuzzleFlash")
								if flash then
									local num = Instance.new("NumberValue")
									local tween = TS:Create(num, TweenInfo.new(0.1), {Value = 1})
									tween:Play()
									local muzzleThread
									flash.Enabled = true
									muzzleThread = coroutine.create(function()
										repeat
											flash.Transparency = NumberSequence.new(num.Value)
											task.wait(1/30)
										until tween.PlaybackState == Enum.PlaybackState.Completed
										tween:Destroy()
										tween = nil
										num:Destroy()
										num = nil
										flash.Enabled = false
										coroutine.yield()
										coroutine.close(muzzleThread)
									end)
									coroutine.resume(muzzleThread)
								end
								task.wait(config.OnUsed:GetAttribute("Firerate")/1.1)
							end
						end
					elseif curAmmo.Value <= 0 then
						reloadFunc(tool, config)
					elseif reloadDisable then
						curAmmo.Changed:Wait()
					elseif tool.Parent == nil then
						break
					else
						warn("An unknown issue occurred whilst trying to shoot", tool.Name)
						task.wait() --nobody likes freezing
					end
				until input.UserInputState == Enum.UserInputState.End or input.UserInputState == Enum.UserInputState.Cancel
			end
		end
		
		controls.Register("Primary Fire", true, shoot)
	else
		controls.Unregister("Primary Fire")
		controls.Unregister("Reload Weapon")
	end
end)