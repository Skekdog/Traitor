local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalCharacter = require(ReplicatedStorage.Shared.Character.LocalCharacter)
local GetDeterminer = require(ReplicatedStorage.Shared.Grammar.GetDeterminer)
local PossessiveApostrophe = require(ReplicatedStorage.Shared.Grammar.PossessiveApostrophe)
local Mouse = require(script.Parent.Mouse)
local StringWithDeterminer = require(ReplicatedStorage.Shared.Grammar.StringWithDeterminer)
local ToRoundTime = require(ReplicatedStorage.Shared.Grammar.ToRoundTime)
local UIManager = require(ReplicatedStorage.Shared.Interface.UILib.UIManager)
local ScreenMessage = require(ReplicatedStorage.Shared.Interface.Util.ScreenMessage)
local ClientInventory = require(ReplicatedStorage.Shared.LocalState.ClientInventory)
local LocalParticipantInfo = require(ReplicatedStorage.Shared.LocalState.LocalParticipantInfo)
local LocalRoundInfo = require(ReplicatedStorage.Shared.LocalState.LocalRoundInfo)
local FullParse = require(ReplicatedStorage.Shared.ParseString.FullParse)
local GetDisplayName = require(ReplicatedStorage.Shared.RoundRule.Common.GetDisplayName)
local Defaults = require(ReplicatedStorage.Shared.RoundRule.Defaults)
local Types = require(ReplicatedStorage.Shared.RoundRule.Types)

local corpseUi = UIManager.WaitForUI("CorpseInfo") :: UIManager.UI & {Object: typeof(UIManager.UnregisteredUIs.CorpseInfo)}
local object = corpseUi.Object.CorpseInfo.ScrollingFrame

local function colouredText(text: string, colour: Color3): string
    return `<font color='#{colour:ToHex()}'>{text}</font>`
end

local function highlightedText(text: string): string
    return colouredText(text, Color3.fromRGB(66, 135, 245))
end

local flavourTexts: {[Types.GeneralDamageSource]: string} = {
    Fall = `Their injuries indicate a {highlightedText("fatal fall")}.`,
    Drown = `Their clothes are drenched and there are no signs of struggle. They probably {highlightedText("drowned.")}.`,
    Explode = `Their singed clothes and wounds indicate a terrible {highlightedText("explosion")}.`,
	Burn = `Smells like {highlightedText("burnt flesh")} around here...`,
    Stab = `They were {highlightedText("stabbed and cut")} before quickly {highlightedText("bleeding")} to death.`,
    Shot = `It is obvious that they were {highlightedText("shot")} to death.`,
    Bludgeon = `The body is {highlightedText("bruised and battered")}. Evidently some {highlightedText("blunt-force trauma")} was at hand.`,
    Crush = `Many of their bones are broken. The impact of a {highlightedText("heavy object")} likely killed them.`,
    Stomp = `Their body looks flattened and miserable. It looks like they were {highlightedText("stomped")}.`,
	Magic = `{highlightedText("Otherworldly forces")} brought about this death.`,
    Poison = `A strong chemical scent indicates that {highlightedText("poison")} was their downfall.`,
    Other = `The lead-up to their fate is unclear.`,
}

local flavourTextsWithWeapon: {[Types.GeneralDamageSource]: string} = {
    Shot = "It is obvious that they were shot to death. It looks like %s.",
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
    Other = "rbxassetid://17079244437",
    Stomp = "rbxassetid://78517882762574",
}

local function getItemAttackType(item: Types.DamageSource): Types.GeneralDamageSource
    if typeof(item) == "table" then
        return item.Base.DamageKind or "Other"
    else
        return item
    end
end

local function getFlavourText(source: Types.DamageSource): string?
    local attackType: Types.GeneralDamageSource = getItemAttackType(source)
    if typeof(source) == "table" then
        local weaponName = GetDisplayName(source.Base)
        return if flavourTextsWithWeapon[attackType] then flavourTextsWithWeapon[attackType]:format(StringWithDeterminer(weaponName)) else flavourTexts[attackType]
    end

    return flavourTexts[attackType] or error("Unknown death type: " .. source)
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

local corpseModel: Instance?
local corpseName: string

local function getDistanceToCorpse(): number
    if not corpseModel or not corpseModel:IsA("Model") or not corpseModel.PrimaryPart then
        return math.huge
    end

    local root = LocalCharacter.RootPart()
    if not root then
        return math.huge
    end

    return (root.Position - corpseModel.PrimaryPart.Position).Magnitude
end

local confirmDeathButton = corpseUi.Object.Actions.ConfirmDeath
confirmDeathButton.Activated:Connect(function()
    if getDistanceToCorpse() > Mouse.CorpseInteractDistance then
        return ScreenMessage("Error", "You must be near the body to confirm death.")
    end
    ReplicatedStorage.Remotes.ClientServer.ConfirmDeath:FireServer(corpseName)
end)

local callRoleButton = corpseUi.Object.Actions.CallRole
callRoleButton.Activated:Connect(function()
    if getDistanceToCorpse() > Mouse.CorpseInteractDistance then
        return ScreenMessage("Error", "You must be near the body to call a role over.")
    end
    ReplicatedStorage.Remotes.ClientServer.CallRole:FireServer(corpseName)
end)

return function(corpseInfo: Types.ClientCorpseView?)
    if not corpseInfo then
        return
    end

    for _, v in object:GetChildren() do
        if v.Name:split("_")[1] == "AdditionalIcon" then
            v:Destroy()
        end
    end

    local ownParticipant = LocalParticipantInfo.GetParticipant()

    corpseName = corpseInfo.Name
    local participant = LocalParticipantInfo.GetParticipant(corpseName)

    corpseModel = workspace.Characters:FindFirstChild(corpseName)
    local withinRange = getDistanceToCorpse() <= Mouse.CorpseInteractDistance

    local bodyIdentified = if corpseModel then not corpseModel:GetAttribute("Unidentified") else false
    confirmDeathButton.Visible = not bodyIdentified and ownParticipant.Status() == "Alive" and withinRange

    local gamemode = LocalRoundInfo.Gamemode()

    local callRoleVisible = false -- sadly trying to set directly with these conditions is a type error. idk if its a valid type error, lua(u)'s "and" system is weird.
    if gamemode and gamemode.RoleCanCallToCorpse and bodyIdentified and ownParticipant.Status() == "Alive" and ownParticipant.Role().Definition ~= gamemode.RoleCanCallToCorpse then
        callRoleVisible = withinRange
    end

    callRoleButton.Visible = callRoleVisible

    information.Text = "Click on an icon to reveal detailed information."

    local source: Types.DamageSource = if typeof(corpseInfo.DamageSource) == "table" then ClientInventory.CreateReplicatedItem(corpseInfo.DamageSource) else corpseInfo.DamageSource

    local weaponName = if typeof(source) == "table" then GetDisplayName(source) else source
    object.MurderWeapon.TextLabel.Text = weaponName

    local flavourText = getFlavourText(source)
    object.MurderWeapon:SetAttribute("Description", flavourText)

    object.MurderWeapon.ImageContent = if typeof(source) == "table" and source.IconContent ~= Content.none then source.IconContent else Content.fromUri(flavourImages[getItemAttackType(source)])

    local timeNow = workspace:GetServerTimeNow()
    object.DeathTime.TextLabel.Text = ToRoundTime(corpseInfo.DeathTime, timeNow)

    local timeSinceDeath = tostring(math.round(timeNow - corpseInfo.DeathTime))
    object.DeathTime:SetAttribute("Description", `From their now-stopped watch, you can tell that they died {highlightedText(timeSinceDeath)} {if timeSinceDeath == "1" then "second" else "seconds"} ago.`)

    object.FreeKill.Visible = corpseInfo.WasFreeKill or false
    object.Headshot.Visible = corpseInfo.WasHeadshot or false
    object.SD.Visible = corpseInfo.WasSelfDefense or false

    for _, replicate in corpseInfo.EquipmentList do
        local item = ClientInventory.CreateReplicatedItem(replicate)
        local formattedItemName = GetDeterminer(GetDisplayName(item)) .. " " ..  highlightedText(GetDisplayName(item))
        table.insert(corpseInfo.AdditionalIcons, {
            Name = item.Name,
            Description = string.format(item.CorpseIconDescription or "They had %s.", formattedItemName),
            Icon = item.IconContent,
        })
    end

    local kills = corpseInfo.KillList
    local killText = `They kept a list of victims, confirming the death{if #kills == 1 then "" else "s"} of: `

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
        icon.ImageContent = v.Icon
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

    local role = participant.Role()

    if role ~= Defaults.Role then
        corpseUi.Object.TitleBar.Title.Text = `{role:FormatString(`@{PossessiveApostrophe(corpseName)}`)} Corpse | {role:GetFormattedName()}`
        local determiner = StringWithDeterminer(GetDisplayName(role.Definition)):split(" ")[1]
        object.Avatar:SetAttribute("Description", `This is the body of {role:FormatString(corpseName)}. They were {determiner} {role:GetFormattedName()}.`)
    else
        corpseUi.Object.TitleBar.Title.Text = `@{PossessiveApostrophe(corpseName)} Corpse`
        object.Avatar:SetAttribute("Description", `This is the body of {corpseName}.`)
    end

    task.defer(function()
        local thumbnail = Players:GetUserThumbnailAsync(corpseInfo.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
        object.Avatar.Image = thumbnail
    end)

    corpseUi:ToggleVisible(true)
end