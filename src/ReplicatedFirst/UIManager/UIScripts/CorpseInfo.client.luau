local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UIManager = require(script.Parent.Parent)
local API = require(script.Parent.Parent.Parent.API)
local LocalRoundInfo = require(script.Parent.Parent.Parent.LocalRoundInfo)
local Types = require(script.Parent.Parent.Parent.RoundHandler.Types)

local corpseUi = UIManager.WaitForUI("CorpseInfo")
local object = corpseUi.Object :: typeof(UIManager.UnregisteredUIs.CorpseInfo)

local flavourTexts: {[Types.MurderWeapon]: string} = {
	Crush = "Many of their bones are broken. It seems the impact of a heavy object killed them.",
	Firearm = "It is obvious that they were shot to death. Moreover, it appears %s was used to kill them.",
	Fall = "Their injuries indicate a fatal fall.",
	Explosion = "Their wounds and singed clothes indicate that an explosion brought about their demise.",
	Blunt = "The body is bruised and battered. Evidently some blunt-force trauma was at hand.",
	Drown = "Their drenched clothes and lack of struggle indicates a watery fate.",
	Blade = "They were stabbed and cut before quickly bleeding to death.",
	Burn = "Smells of burnt spy around here...",
	Mutation = "It seems their DNA was mutated by teleporter emissions.",
	Suicide = "This spy couldn't take it anymore and took their own life.",
}

ReplicatedStorage:WaitForChild("RoundHandler").SendCorpseInfo.OnClientEvent:Connect(function(corpseInfo: Types.CorpseInfo)
    local weapon
    local deathType: Types.MurderWeapon
    if typeof(corpseInfo.MurderWeapon) == "table" then
        weapon = corpseInfo.MurderWeapon.Name
        deathType = corpseInfo.MurderWeapon.AttackType or "Suicide"
    else
        weapon = corpseInfo.MurderWeapon
        deathType = corpseInfo.MurderWeapon
    end
    object.MurderWeapon.TextLabel.Text = weapon

    local flavourText = flavourTexts[deathType]
    if deathType == "Firearm" and weapon ~= "Firearm" then
        flavourText = flavourText:format(API.StringWithDeterminer(weapon))
    end
    object.MurderWeapon:SetAttribute("Description", flavourTexts[deathType])

    API.ToRoundTime(LocalRoundInfo.GetStartTime(), corpseInfo.DeathTime)
    object.FreeKill.Visible = corpseInfo.FreeKill
    object.Headshot.Visible = corpseInfo.Headshot
    object.SD.Visible = corpseInfo.SelfDefense

    local equipment = corpseInfo.EquipmentList
    local equipmentText = "You find"
    if #equipment > 0 then
        for i, v in equipment do
            if i == 1 then
                equipmentText ..= ` {API.StringWithDeterminer(equipment[1].Name)}`
            elseif i == #equipment then
                equipmentText ..= ` and {API.StringWithDeterminer(equipment[i].Name)}`
            else
                equipmentText ..= `, {API.StringWithDeterminer(equipment[i].Name)}`
            end
        end
        equipmentText ..= " on their corpse."
        object.EquipmentList:SetAttribute("Description", equipmentText)
    else
        object.EquipmentList.Visible = false
    end

    local kills = corpseInfo.KillList
    local killText = `They had a list of kills, confirming the death{if #kills == 1 then "" else "s"} of: `

    if #kills > 0 then
        for i, v in kills do
            if i == 1 then
                killText ..= v
            elseif i == #kills then
                killText ..= ` and {v}`
            else
                killText ..= `, {v}`
            end
        end
        killText ..= "."
        object.KillList:SetAttribute("Description", killText)
    else
        object.KillList.Visible = false
    end

    object.Title.Text = `@{corpseInfo.FormattedName}'s Corpse | {corpseInfo.Role.FormattedName}`

    local determinerRole = API.StringWithDeterminer(corpseInfo.Role.Name):split(" ")[1]
    object.Avatar:SetAttribute("Description", `This is the body of {corpseInfo.FormattedName}. They were {determinerRole} {corpseInfo.Role.FormattedName}.`)

    --todo: is this blocking?
    object.Avatar.Image = game:GetService("Players"):GetUserThumbnailAsync(corpseInfo.Player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)

    corpseUi:ToggleVisible(true)
end)
