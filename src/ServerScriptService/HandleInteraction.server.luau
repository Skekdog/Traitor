local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local TS = game:GetService("TweenService")
local RoundHandler = require(ReplicatedFirst.RoundHandler.RoundHandler)

ReplicatedStorage.ClientServer.Interaction.OnServerEvent:Connect(function(plr, part: BasePart & {Parent: Instance})
	local char = plr.Character :: Model & {Humanoid: Humanoid, PrimaryPart: BasePart}

	local roundId = ServerStorage:GetAttribute("RoundID")
	if not roundId then return end

	local round = RoundHandler.GetRound(roundId)
	
	if char then
		local hum = char.Humanoid
		if hum.Health > 0 and (char.PrimaryPart.Position-part.Position).Magnitude < 10 then
			local map = round.Map
			local actionItems = map.Map:FindFirstChild("__ActionItems")
			local doors = map.Map:FindFirstChild("__Doors")
			local props = map:FindFirstChild("Props")
			if actionItems and actionItems:IsAncestorOf(part) then
				(require)(part.Parent:FindFirstChildOfClass("ModuleScript"))()
			elseif doors and doors:IsAncestorOf(part) and not part:GetAttribute("Opening") then
				part:SetAttribute("Opening", true)
				part:SetAttribute("Open", not part:GetAttribute("Open"))
				local angle = math.rad(part:GetAttribute("Open") and -90 or 90)
				
				local hinge = part.CFrame * CFrame.new((part.Size.X/2)*-1, 0, 0)
				local newCFrame = (hinge*CFrame.Angles(0, angle, 0)):ToWorldSpace(hinge:ToObjectSpace(part.CFrame))
				
				TS:Create(part, TweenInfo.new(1, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {CFrame = newCFrame}):Play()
				task.delay(1.02, function()part:SetAttribute("Opening", false)end)
				
				local sounds = {}
				for _, v in part:GetChildren() do
					if v:IsA("Sound") and v.Name == (part:GetAttribute("Open") and "OpenSound" or "CloseSound") then
						table.insert(sounds, v)
					end
				end
				sounds[math.random(1, #sounds)]:Play()
			elseif props and props:IsAncestorOf(part) then
				local prop = part.Parent
				if prop.Name:sub(1, 10) ~= "Equipment_" then return end
				
				if prop.Name:sub(11) == "Health Station" or prop.Name:sub(11) == "Death Station" then
					if part:GetAttribute("InUseBy"):match(plr.Name..";") then return end
					
					part:SetAttribute("InUseBy", `{part:GetAttribute("InUseBy")}{plr.Name};`)
					while (hum.Health < hum.MaxHealth) and ((char.PrimaryPart.Position-part.Position).Magnitude < 6) and (part:FindFirstAncestorOfClass("Workspace")) and (hum.Health > 0) do
						if part:GetAttribute("CurrentCharge") <= 0 then
							part:GetAttributeChangedSignal("CurrentCharge"):Wait()
						end
						hum.Health += 1
						part:SetAttribute("CurrentCharge", part:GetAttribute("CurrentCharge") - 1)
						task.wait(0.5)
					end
					if part:GetAttribute("InUseBy") then
						part:SetAttribute("InUseBy", part:GetAttribute("InUseBy"):gsub(plr.Name..";", ""))
					end
				end
			end
		end
	end
end)