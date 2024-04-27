local ReplicatedStorage = game:GetService("ReplicatedStorage")
local uiManager = require(game:GetService("ReplicatedFirst").UIManager)

local d = "Description"
local df = d.."Formatted"

local frame = script.Parent
local infoGrid = frame.CorpseInfo
local murderWeapon = infoGrid.MurderWeapon
local deathTime = infoGrid.DeathTime
local avatar = infoGrid.Avatar
local equipmentList = infoGrid.EquipmentList
local _DNADuration = infoGrid.DNADuration
local killList = infoGrid.KillList
local freeKill = infoGrid.FreeKill
local headshot = infoGrid.Headshot
local sd = infoGrid.SD

local function convertTime(rawSeconds)
	local minutes = tostring(math.floor(rawSeconds/60))
	local seconds = tostring(math.fmod(rawSeconds,60))

	if string.len(minutes) < 2 then
		minutes = "0"..minutes
	end
	if string.len(seconds) < 2 then
		seconds = "0"..seconds
	end
	
	return minutes..":"..seconds
end

local function diffTime(Time:number): number
	return workspace:GetServerTimeNow()-Time
end

local weapons = {}
for _,v in game.ReplicatedStorage.Items:GetChildren() do
	if v:GetAttribute("Weapon") then
		local explosive = v.Configuration.Damage.Uniques:GetAttribute("Explos")
		weapons[v.Name] = explosive
	end
end
weapons["Explosion"] = true

flavourText = {
	Crush = "Many of their bones are broken. It seems the impact of a heavy object killed them.",
	Bullet = "It is obvious that they were shot to death. Moreover, it appears a%s was used.",
	Fall = "Their injuries indicate a fatal fall.",
	Explosion = "Their wounds and singed clothes indicate that an explosion brought about their demise.",
	Blunt = "The body is bruised and battered. Evidently some blunt-force trauma was at hand.",
	Drown = "Their drenched clothes and lack of struggle indicates a watery fate.",
	Stab = "They were stabbed and cut before quickly bleeding to death.",
	Burn = "Smells of burnt spy around here...",
	Teleporter = "It seems their DNA was mutated by teleporter emissions.",
	Other = "It is unclear what caused this spy's demise.",
	Suicide = "This spy couldn't take it anymore and took their own life.",
}

local function showCorpse(info)
	avatar.Image = game:GetService("Players"):GetUserThumbnailAsync(info.UserID,Enum.ThumbnailType.HeadShot,Enum.ThumbnailSize.Size420x420)

	local weapon = info.MurderWeapon
	if weapon == "__!!Explosion" then weapon = "Explosion" end
	murderWeapon.TextLabel.Text = weapon

	if weapons[weapon] then murderWeapon.Image = "rbxassetid://1789477853" end

	local dthTm = math.round(diffTime(info.DeathTime))
	deathTime.TextLabel.Text = convertTime(dthTm)

	avatar:SetAttribute(df,string.format(avatar:GetAttribute(d),info.Name,("<font color='"..info.RoleColour.."'>"..info.Role.."</font>")))
	murderWeapon:SetAttribute(df,string.format(murderWeapon:GetAttribute(d),weapon))
	deathTime:SetAttribute(df,string.format(deathTime:GetAttribute(d),dthTm))

	if info.FreeKill then freeKill.Visible = true
	else freeKill.Visible = false end
	
	if info.Headshot then headshot.Visible = true
	else headshot.Visible = false end

	if info.SD then sd.Visible = true
	else sd.Visible = false end

	if info.DNADuration then

	end
	
	local splitKills = info.KillList:split(";")
	table.remove(splitKills,#splitKills)
	if #splitKills > 0 then
		local kills = "\n"
		for i,v in splitKills do
			local prefix = (i == 1 and "") or (i == #splitKills and " and ") or ", "
			kills = kills..prefix..v
		end
		killList:SetAttribute(df,string.format(killList:GetAttribute(d),kills))
		killList.Visible = true
	else killList.Visible = false end
	
	local splitEquipment = info.EquipmentList:split(";")
	table.remove(splitEquipment,#splitEquipment)
	if #splitEquipment > 0 then
		local list = "\n"
		for i,v in splitEquipment do
			local prefix = (i == 1 and "") or (i == #splitEquipment and " and ") or ", "
			list = list..prefix..v
		end
		equipmentList:SetAttribute(df,string.format(equipmentList:GetAttribute(d),list))
		equipmentList.Visible = true 
	else equipmentList.Visible = false end
	
	frame.TextLabel.Text = "@"..info.Name.."'s Corpse | "..("<font color='"..info.RoleColour.."'>"..info.Role.."</font>")
	
	uiManager.WaitForUI("Inspect Corpse"):ToggleVisible(true)
end

for _,v in pairs(infoGrid:GetChildren()) do
	if v.ClassName == "ImageButton" then
		v.MouseButton1Click:Connect(function()
			frame.Information.Text = v:GetAttribute("DescriptionFormatted")
		end)
	end
end

ReplicatedStorage.ServerClient.DeliverCorpseInfo.OnClientEvent:Connect(showCorpse)