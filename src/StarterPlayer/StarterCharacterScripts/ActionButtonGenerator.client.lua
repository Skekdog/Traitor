local CS = game:GetService("CollectionService")
local UIS = game:GetService("UserInputService")
local CAS = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")

local plr = Players.LocalPlayer

local actions = plr.PlayerGui:WaitForChild("Buttons"):WaitForChild("BottomBar"):WaitForChild("Actions")
local ControlManager = require(ReplicatedFirst.ControlManager)
local settingsManager = require(ReplicatedFirst:WaitForChild("SettingsManager"))

local scriptCons = game:WaitForChild("ClientStorage"):WaitForChild("ScriptConnections")

scriptCons.DisableActionFunction.OnInvoke = function(action,disable)
	actions:FindFirstChild(action):SetAttribute("Disable",disable)
	actions:FindFirstChild(action).Visible = false
end

for i,v in pairs(CS:GetTagged("Actionable")) do
	local fName = v:GetFullName()

	local event = v:GetAttribute("Event")
	local actionType = v:GetAttribute("Type")
	local actionText = v:GetAttribute("Action")
	local accessZone = v:WaitForChild("ActionAccess",1)
	
	if not event then error("Event attribute not found in "..fName,0) end
	if not actionType then error("Type attribute not found in "..fName,0) end
	if not actionText then warn("Action attribute not found in "..fName,0) end
	
	if not accessZone then error("AccessZone ObjectValue not found in "..fName,0)
	elseif not accessZone.Value then error("AccessZone ObjectValue not set in "..fName,0)
	elseif accessZone.Value.ClassName ~= "Part" then
		error("AccessZone ObjectValue does not point to a Part in "..fName,0) end
	
	
	local id = actionType..tostring(i)
	local sample = actions.Sample:Clone()
	
	accessZone = v:FindFirstChild("ActionAccess").Value
	sample.Action.Text = actionText
	sample.TextButton.Text = "Click"
	
	sample.Name = id
	sample.Parent = actions
	
	local function action()
		CAS:UnbindAction("GeneratedAction"..id) --optional arguments for functions are not possible
		if actionType == "Ladder" then
			plr.Character:SetPrimaryPartCFrame(CFrame.new(accessZone.AccessPoint.WorldPosition.X,
				plr.Character.PrimaryPart.Position.Y,
				accessZone.AccessPoint.WorldPosition.Z
				))
		end
		
		scriptCons:FindFirstChild(event):Fire(v,actionText,id)
	end
	
	sample.TextButton.MouseButton1Click:Connect(action)
	
	local keybinded
	
	if UIS.KeyboardEnabled then
		function keybinded()
			if actionType == "Ladder" then --ladders are special
				if settingsManager.GetSetting("Snap to Ladders") and (plr:GetAttribute("LadderTime") or 0) + 1.5 < workspace:GetServerTimeNow() then
					action()
					return
				end
			end

			local keybind = workspace["__Map"].Configuration.Keybinds:GetAttribute(actionType)

			sample.TextButton.Text = keybind

			ControlManager.Register("GeneratedAction"..id, false, action)
		end
	end
	accessZone.Touched:Connect(function(part)
		if part == plr.Character.HumanoidRootPart then
			accessZone.TouchEnded:Connect(function(part2)
				if part2 == part then
					sample.Visible = false
					CAS:UnbindAction("GeneratedAction"..id)
				end
			end)
			sample.Visible = true and not sample:GetAttribute("Disable")
			keybinded()
		end
	end)
end