--!nocheck
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")

local plr = Players.LocalPlayer

local scriptCons = game:WaitForChild("ClientStorage"):WaitForChild("ScriptConnections")

local event = scriptCons.ClimbEvent
local func = scriptCons.DisableActionFunction

event.Event:Connect(function(v, _, id)
	func:Invoke(id, true)
	local plrModule = require((plr :: any).PlayerScripts:WaitForChild("PlayerModule"))

	local top = v.AccessZone:FindFirstChild("Top")
	local bottom = v.AccessZone:FindFirstChild("Bottom")

	local char = plr.Character
	local root = char.HumanoidRootPart
	local hum = char.Humanoid

	local climbForce = root.ClimbVelocity
	climbForce.Attachment0 = root.RootRigAttachment
	climbForce.Enabled = true

	hum.WalkSpeed = 0 --eh

	local began
	local change
	local jumpC

	local function leave()
		began:Disconnect()
		if change then --got an error randomly that change was nil, so just do this
					   --treat the symptoms, not the cause
			change:Disconnect()
		end
		jumpC:Disconnect()

		climbForce.Enabled = false
		climbForce.LineVelocity = 0
		hum.WalkSpeed = 16 --close enough
		func:Invoke(id, false)
		plr:SetAttribute("LadderTime", workspace:GetServerTimeNow()) --Cooldown between *snapping* to ladder
												 --I don't intend a cooldown for non-snap laddering
	end
	
	local hbCon
	hbCon = game:GetService("RunService").Heartbeat:Connect(function()
		if root.Position.Y > top.WorldPosition.Y and climbForce.LineVelocity == 10 then
			hbCon:Disconnect()
			leave()
			return
		elseif root.Position.Y < bottom.WorldPosition.Y and climbForce.LineVelocity == -10 then
			hbCon:Disconnect()
			leave()
			return
		end
	end)
	
	local function move(action: string, state: Enum.UserInputState, input: InputObject)
		if (state == Enum.UserInputState.End and (action == "Up" or action == "Down")) or action == "Stop" then
			climbForce.LineVelocity = 0
			return
		end
		if state == Enum.UserInputState.Begin or Enum.UserInputState.Change then
			if action == "Up" then
				climbForce.LineVelocity = 10
			elseif action == "Down" then
				climbForce.LineVelocity = -10
			end
		end
	end
	
	began = UIS.InputBegan:Connect(function(input: InputObject, proc)
		if not proc then
			if input.UserInputState ~= Enum.UserInputState.End and 
				(input.UserInputType == Enum.UserInputType.Keyboard or
					input.UserInputType == Enum.UserInputType.Touch) then

				local function doMove()
					local movementVector = plrModule:GetControls():GetMoveVector()
					if movementVector.Z < 0 then --forward
						move("Up", input.UserInputState, input)
					elseif movementVector.Z > 0 then --backward
						move("Down", input.UserInputState, input)
					elseif movementVector.Z == 0 then --stop
						move("Stop", input.UserInputState, input)
					end
				end

				change = input.Changed:Connect(doMove)
				doMove()
			end
		end
	end)
	jumpC = UIS.JumpRequest:Connect(leave)
end)