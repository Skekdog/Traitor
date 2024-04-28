local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local TS = game:GetService("TweenService")
local RoundHandler = require(ServerScriptService.RoundHandler.RoundHandler)

ReplicatedStorage.ClientServer.Interaction.OnServerEvent:Connect(function(plr, part: BasePart)
	local char = plr.Character

	local roundId = ServerStorage:GetAttribute("RoundID")
	if not roundId then return end

	local round = RoundHandler.GetRound(roundId)
	
	if char then
		local hum = char.Humanoid
		if hum.Health > 0 and (char.PrimaryPart.Position-part.Position).Magnitude < 10 then
			if round.Map.ActionItems:IsAncestorOf(part) then
				require((part :: any).Parent:FindFirstChildOfClass("ModuleScript"))()
			elseif round.Map.Doors:IsAncestorOf(part) and not part:GetAttribute("Opening") then
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
			elseif round.Map.Props:IsAncestorOf(part) then
				local prop = part.Parent
				if prop.Name:sub(1, 10) ~= "Equipment_" then return end
				
				local data = prop:FindFirstChild("ToolData")
				if not data then return end
				
				if prop.Name:sub(11) == "Health Station" or prop.Name:sub(11) == "Death Station" then
					local curCharge = data:FindFirstChild("CurrentCharge")
					if not curCharge then return end
					if data.InUseBy.Value:match(plr.Name..";") then return end
					
					data.InUseBy.Value = data.InUseBy.Value..plr.Name..";"
					while (hum.Health < hum.MaxHealth) and ((char.PrimaryPart.Position-part.Position).Magnitude < 6) and (part:FindFirstAncestorOfClass("Workspace")) and (hum.Health > 0) do
						if curCharge.Value <= 0 then
							data.CurrentCharge.Changed:Wait()
						end
						hum.Health += data:GetAttribute("Health")
						curCharge.Value -= 1
						task.wait(data:GetAttribute("Cooldown"))
					end
					if data:FindFirstChild("InUseBy") then
						data.InUseBy.Value = data.InUseBy.Value:gsub(plr.Name..";", "")
					end
				end
			end
		end
	end
end)