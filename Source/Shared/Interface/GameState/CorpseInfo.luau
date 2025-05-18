local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StringWithDeterminer = require(ReplicatedStorage.Shared.Grammar.StringWithDeterminer)
local ToRoundTime = require(ReplicatedStorage.Shared.Grammar.ToRoundTime)
local UIManager = require(ReplicatedStorage.Shared.Interface.UILib.UIManager)
local GetItemDefinition = require(ReplicatedStorage.Shared.LocalState.GetItemDefinition)
local LocalRoundInfo = require(ReplicatedStorage.Shared.LocalState.LocalRoundInfo)
local FullParse = require(ReplicatedStorage.Shared.ParseString.FullParse)
local GetDisplayName = require(ReplicatedStorage.Shared.RoundRule.Common.GetDisplayName)
local Defaults = require(ReplicatedStorage.Shared.RoundRule.Defaults)
local Types = require(ReplicatedStorage.Shared.RoundRule.Types)

local corpseUi = UIManager.WaitForUI("CorpseInfo") :: UIManager.UI & {Object: typeof(UIManager.UnregisteredUIs.CorpseInfo)}
local object = corpseUi.Object.CorpseInfo

local function colouredText(text: string, colour: Color3): string
    return `<font color='#{colour:ToHex()}'>{text}</font>`
end

local function highlightedText(text: string): string
    return colouredText(text, Color3.fromRGB(66, 135, 245))
end

local flavourTexts: {[Types.GeneralDamageSource]: string} = {
    Fall = `Their injuries indicate a {highlightedText("fatal fall")}.`,
    Drown = `Their drenched clothes and lack of struggle indicate a {highlightedText("watery fate")}.`,
    Explode = `Their wounds and singed clothes indicate that an {highlightedText("explosion")} brought about their demise.`,
	Burn = `Smells of {highlightedText("burnt spy")} around here...`,
    Stab = `They were {highlightedText("stabbed and cut")} before quickly {highlightedText("bleeding")} to death.`,
    Shot = `It is obvious that they were {highlightedText("shot")} to death.`,
    Bludgeon = `The body is {highlightedText("bruised and battered")}. Evidently some {highlightedText("blunt-force trauma")} was at hand.`,
    Crush = `Many of their bones are broken. It seems the impact of a {highlightedText("heavy object")} killed them.`,
	Magic = `{highlightedText("Otherworldly forces")} brought about this spy's death.`,
    Poison = `A strong chemical odor suggests that {highlightedText("poison")} was the cause of this spy's demise.`,
    Other = `It is unclear how this spy met their fate.`,
}

local flavourTextsWithWeapon: {[Types.GeneralDamageSource]: string} = {
    Shot = "It is obvious that they were shot to death. Moreover, it appears %s was used.",
}

local flavourImages: {[Types.GeneralDamageSource]: string} = {
    Fall = "rbxassetid://27225585",
    Drown = "rbxassetid://1094356207",
    Explode = "rbxassetid://1789477853",
    Burn = "rbxassetid://5664716195",
    Stab = "rbxassetid://949752421",
    Shot = "rbxassetid://700497561",
    Bludgeon = "rbxassetid://15819411457",
    Crush = "rbxassetid://953809995",
    Magic = "rbxassetid://15244435410",
    Poison = "rbxassetid://79725625736870",
    Other = "rbxassetid://17079244437"
}

local function getItemFromName(name: string): Types.AnyItemDefinition?
    return GetItemDefinition(name)
end

local function getItemAttackType(name: string): Types.GeneralDamageSource
    local item = getItemFromName(name)
    if item then
        if item.Kind == "Gun" then
            return "Shot"
        elseif item.Kind == "Grenade" then
            return "Explode"
        elseif item.Kind == "Melee" then
            return item.DamageKind
        elseif item.Kind == "Item" then
            return "Other"
        end
        error("Unknown item kind: " .. item.Kind)
    else
        return name :: Types.GeneralDamageSource
    end
end

local function getFlavourText(deathType: Types.NamedDamageSource): string?
    local attackType: Types.GeneralDamageSource = getItemAttackType(deathType)
    if attackType ~= deathType then
        return if flavourTextsWithWeapon[attackType] then flavourTextsWithWeapon[attackType]:format(StringWithDeterminer(deathType)) else flavourTexts[attackType]
    end

    return flavourTexts[attackType] or error("Unknown death type: " .. deathType)
end

local information = corpseUi.Object.Information
local function onIconClicked(icon: Instance)
    information.Text = icon:GetAttribute("Description") :: string
end

for _, v in object:GetChildren() do
    if v:IsA("ImageButton") then
        v.Activated:Connect(function()
            onIconClicked(v)
        end)
    end
end

return function(corpseInfo: Types.CorpseView?)
    if not corpseInfo then
        return
    end

    for _, v in object:GetChildren() do
        if v.Name:split("_")[1] == "AdditionalIcon" then
            v:Destroy()
        end
    end

    information.Text = "Click on an icon to reveal detailed information."

    object.MurderWeapon.TextLabel.Text = corpseInfo.DamageSource

    local flavourText = getFlavourText(corpseInfo.DamageSource)
    object.MurderWeapon:SetAttribute("Description", flavourText)

    object.MurderWeapon.Image = flavourImages[getItemAttackType(corpseInfo.DamageSource)]

    local timeNow = workspace:GetServerTimeNow()
    object.DeathTime.TextLabel.Text = ToRoundTime(corpseInfo.DeathTime, timeNow)

    local timeSinceDeath = tostring(math.round(timeNow - corpseInfo.DeathTime))
    object.DeathTime:SetAttribute("Description", `Their watch stopped, indicating that they died {highlightedText(timeSinceDeath)} {if timeSinceDeath == "1" then "second" else "seconds"} ago.`)

    object.FreeKill.Visible = corpseInfo.WasFreeKill or false
    object.Headshot.Visible = corpseInfo.WasHeadshot or false
    object.SD.Visible = corpseInfo.WasSelfDefense or false

    local equipment = corpseInfo.EquipmentList
    local equipmentText = "You find"
    if #equipment > 0 then
        for i, v in equipment do
            v = highlightedText(v)
            if i == 1 then
                equipmentText ..= ` {StringWithDeterminer(v)}`
            elseif i == #equipment then
                equipmentText ..= ` and {StringWithDeterminer(v)}`
            else
                equipmentText ..= `, {StringWithDeterminer(v)}`
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

    for _, v in corpseInfo.AdditionalIcons do
        local icon = object.MurderWeapon:Clone()
        icon.Image = v.Icon
        icon:SetAttribute("Description", FullParse(v.Description))
        icon.Name = "AdditionalIcon_" .. v.Name
        icon.ScaleType = Enum.ScaleType.Fit
        icon.Visible = true
        icon.TextLabel.Text = if v.DisplayText then FullParse(v.DisplayText) else ""
        icon.Parent = object

        icon.Activated:Connect(function()
            onIconClicked(icon)
        end)
    end

    local name = corpseInfo.Name
    local role = LocalRoundInfo.GetPlayerRole(name)

    if role ~= Defaults.Role then
        corpseUi.Object.Title.Text = `{role:GetFormattedString(`@{name}'s`)} Corpse | {role:GetFormattedRoleName()}`
        local determiner = StringWithDeterminer(GetDisplayName(role.Definition)):split(" ")[1]
        object.Avatar:SetAttribute("Description", `This is the body of {role:GetFormattedString(name)}. They were {determiner} {role:GetFormattedRoleName()}.`)
    else
        corpseUi.Object.Title.Text = `@{name}'s Corpse`
        object.Avatar:SetAttribute("Description", `This is the body of {name}.`)
    end

    task.defer(function()
        local thumbnail = Players:GetUserThumbnailAsync(corpseInfo.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
        object.Avatar.Image = thumbnail
    end)

    corpseUi:ToggleVisible(true)
end