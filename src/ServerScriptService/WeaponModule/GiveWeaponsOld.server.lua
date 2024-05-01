local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local conversions = {
	["Deagle"] = "Deagle",
	["Shotgun"] = "XM1014",
	["Glock"] = "Glock",
	["H.U.G.E-249"] = "HUGE",
	["M16"] = "Assault Rifle",
	["Pistol"] = "Pistol",
	["Rifle"] = "Scout",
	["MAC10"] = "SMG",
	
	["Scout"] = "Scout",
	["XM1014"] = "XM1014",
	["HUGE"] = "HUGE",
	["Assault Rifle"] = "Assault Rifle",
	["SMG"] = "SMG",
	["AWP"] = "AWP",
	["Golden Gun"] = "Golden Gun",
	["Grenade"] = "Grenade",
	["Silenced Pistol"] = "Silenced Pistol"
}

local function setup(v)
	v.Name = conversions[v.Name] or v.Name
	local serverItem = ReplicatedStorage.Items:FindFirstChild(v.Name)
	if serverItem then
		local priPart = v:IsA("Model") and v.PrimaryPart or v
		local con
		con = priPart.Touched:Connect(function(part)
			local player = game:GetService("Players"):GetPlayerFromCharacter(part.Parent)
			if player then
				local hum = player.Character:FindFirstChild("Humanoid")
				if hum then
					if hum.Health > 0 then
						for i2, v2 in pairs(player.Inventory:GetChildren()) do
							if v2:GetAttribute("Slot") == serverItem:GetAttribute("Slot") then
								return
							end
						end
						v:Destroy()
						serverItem:Clone().Parent = player.Inventory
						con:Disconnect()
					end
				end
			end
		end)
	end
end

workspace.ChildAdded:Connect(function(child)
	if child.Name:match(ServerStorage:GetAttribute("RoundID") or "") then
		local spawns = child.WeaponSpawns
		for _, v in pairs(spawns:GetChildren()) do
			setup(v)
		end
		spawns.ChildAdded:Connect(setup)
	end
end)