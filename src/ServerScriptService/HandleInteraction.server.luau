local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local ActionItems = require(script.Parent.ActionItems)
local GetRound = require(script.Parent.GetRound)

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
		part:SetAttribute("Open", not part:GetAttribute("Open"))

		TweenService:Create(part, TweenInfo.new(1), {CFrame = part.CFrame * CFrame.Angles(0, math.rad(if part:GetAttribute("Open") then -90 else 90), 0)}):Play()
		
		local sounds = {}
		for _, v in part:GetChildren() do
			if v:IsA("Sound") and v.Name == (part:GetAttribute("Open") and "OpenSound" or "CloseSound") then
				table.insert(sounds, v)
			end
		end
		sounds[math.random(1, #sounds)]:Play()
	elseif props and props:IsAncestorOf(part) then

	end
end)