local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local UIManager = require(script.Parent.Parent)
local StringWithDeterminer = require(script.Parent.Parent.Parent.StringWithDeterminer)
local ToRoundTime = require(script.Parent.Parent.Parent.ToRoundTime)
local Types = require(ReplicatedFirst.RoundHandler.Types)

local corpseUi = UIManager.WaitForUI("CorpseInfo") :: UIManager.UI & {Object: typeof(UIManager.UnregisteredUIs.CorpseInfo)}
local object = corpseUi.Object.CorpseInfo

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

local flavourImages: {[Types.MurderWeapon]: string} = {
    Fall = "rbxassetid://27225585",
    Firearm = "rbxassetid://700497561",
    Explosion = "rbxassetid://1789477853",
    Crush = "rbxassetid://953809995",
    Blunt = "rbxassetid://15819411457",
    Drown = "rbxassetid://1094356207",
    Blade = "rbxassetid://949752421",
    Burn = "rbxassetid://5664716195",
    Mutation = "rbxassetid://2890327",
    Suicide = "rbxassetid://17079244437"
}

local information = corpseUi.Object.Information
for _, v in object:GetChildren() do
    if v:IsA("ImageButton") then
        v.MouseButton1Click:Connect(function()
            information.Text = v:GetAttribute("Description") :: string
        end)
    end
end

return function(corpseInfo: Types.CorpseInfo?)
    if not corpseInfo then
        return
    end
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

    information.Text = "Click on an icon to reveal detailed information."

    local flavourText = flavourTexts[deathType]
    if deathType == "Firearm" and weapon ~= "Firearm" then
        flavourText = flavourText:format(StringWithDeterminer(weapon))
    end
    object.MurderWeapon:SetAttribute("Description", flavourText)

    object.MurderWeapon.Image = flavourImages[deathType]

    local timeNow = workspace:GetServerTimeNow()
    object.DeathTime.TextLabel.Text = ToRoundTime(corpseInfo.DeathTime, timeNow)
    object.DeathTime:SetAttribute("Description", `Their watch stopped, indicating that they died {math.round(timeNow - corpseInfo.DeathTime)} seconds ago.`)

    object.FreeKill.Visible = corpseInfo.FreeKill
    object.Headshot.Visible = corpseInfo.Headshot
    object.SD.Visible = corpseInfo.SelfDefense

    object.DNADuration.Visible = corpseInfo.DNAExpiry ~= nil

    if corpseInfo.DNAExpiry then
        object.DNADuration.TextLabel.Text = ToRoundTime(timeNow, corpseInfo.DNAExpiry)

        if timeNow < corpseInfo.DNAExpiry then
            object.DNADuration:SetAttribute("Description", "The killer left a sample of their DNA on the body. Use a DNA Scanner to find them.")
        else
            object.DNADuration:SetAttribute("Description", "The killer's DNA sample has expired.\n\"There is nothing we can do.\" - Napoleon")
        end
    end

    local equipment = corpseInfo.EquipmentList
    local equipmentText = "You find"
    if #equipment > 0 then
        for i, v in equipment do
            if i == 1 then
                equipmentText ..= ` {StringWithDeterminer(equipment[1].Name)}`
            elseif i == #equipment then
                equipmentText ..= ` and {StringWithDeterminer(equipment[i].Name)}`
            else
                equipmentText ..= `, {StringWithDeterminer(equipment[i].Name)}`
            end
        end
        equipmentText ..= " on their corpse."
        object.EquipmentList:SetAttribute("Description", equipmentText)
        object.EquipmentList.Visible = true
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
        object.KillList.Visible = true
    else
        object.KillList.Visible = false
    end

    corpseUi.Object.Title.Text = `@{corpseInfo.FormattedName}'s Corpse | {corpseInfo.Role.FormattedName}`

    local determinerRole = StringWithDeterminer(corpseInfo.Role.Name):split(" ")[1]
    object.Avatar:SetAttribute("Description", `This is the body of {corpseInfo.FormattedName}. They were {determinerRole} {corpseInfo.Role.FormattedName}.`)

    task.defer(function()
        local thumbnail = Players:GetUserThumbnailAsync(corpseInfo.Player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
        object.Avatar.Image = thumbnail
    end)

    corpseUi:ToggleVisible(true)
end