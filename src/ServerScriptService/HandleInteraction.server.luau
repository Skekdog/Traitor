local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ActionItems = require(script.Parent.ActionItems)
local GetRound = require(script.Parent.GetRound)
local StandardDoor = require(script.Parent.Parent.ReplicatedFirst.StandardDoor)

ReplicatedStorage.ClientServer.Interaction.OnServerEvent:Connect(function(plr: Player, part: unknown)
	local char = plr.Character
	if not char then
		return
	end

	if typeof(part) ~= "Instance" or not part:IsA("BasePart") then
		return
	end

	if not part.Parent then
		return
	end

	local round = GetRound()
	if not round then
		return
	end

	local participant = round:GetParticipant(plr.Name)
	if not participant then
		return
	end
	
	local hum = char:FindFirstChild("Humanoid") :: Humanoid?
	if not hum or hum.Health <= 0 then
		return
	end

	local root = hum.RootPart
	if not root or (root.Position - part.Position).Magnitude > 10 then
		return
	end

	local map = round.Map
	local actionItems = map:FindFirstChild("ActionItems")
	local doors = map:FindFirstChild("Doors")
	local props = map:FindFirstChild("Props")

	if actionItems and actionItems:IsAncestorOf(part) then
		ActionItems.Execute(part:FindFirstAncestorOfClass("Model") :: Model, participant)
	elseif doors and doors:IsAncestorOf(part) and not part:GetAttribute("Opening") then
		part:SetAttribute("Opening", true)

		local angle = part:FindFirstChild("DoorAngle") :: NumberValue or Instance.new("NumberValue")
		if not angle.Parent then
			angle.Name = "DoorAngle"
			angle.Parent = part
		end

		local open = not part:GetAttribute("Open")
		part:SetAttribute("Open", open)

		local initialCFrame = part.CFrame

		StandardDoor(part, initialCFrame, open, angle)
		ReplicatedStorage.ServerClient.TweenStandardDoor:FireAllClients(part, initialCFrame, open, angle)
		
		local sounds = {}
		for _, v in part:GetChildren() do
			if v:IsA("Sound") and v.Name == if open then "OpenSound" else "CloseSound" then
				table.insert(sounds, v)
			end
		end
		sounds[math.random(1, #sounds)]:Play()

		task.wait(1)
		part:SetAttribute("Opening", false)
	elseif props and props:IsAncestorOf(part) then

	end
end)