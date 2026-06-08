local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Message = require(ReplicatedStorage.API.Interface.Message)
local LocalCharacter = require(ReplicatedStorage.Shared.Character.LocalCharacter)
local UIManager = require(ReplicatedStorage.Shared.Interface.UILib.UIManager)
local ClientInventory = require(ReplicatedStorage.Shared.LocalState.ClientInventory)
local LocalParticipantInfo = require(ReplicatedStorage.Shared.LocalState.LocalParticipantInfo)
local LocalRoundInfo = require(ReplicatedStorage.Shared.LocalState.LocalRoundInfo)

local statusEffects = (UIManager.WaitForUI("LeftArea").Object :: typeof(UIManager.UnregisteredUIs.LeftArea)).StatusEffects

local participant = LocalParticipantInfo.GetParticipant()

local function updateFreeKillStatus(): ()
    local hasReason = not not LocalRoundInfo.FreeKill()
    local hasCharacter = not not LocalCharacter.Character()
    statusEffects.FreeKill.Visible = hasCharacter and hasReason
end

LocalRoundInfo.FreeKill:Connect(function(reason)
    if reason and not statusEffects.FreeKill.Visible then
		Message.Chat(`Because you {reason}, you are now a free kill!`)
    end
    updateFreeKillStatus()
end)

LocalCharacter.Character:Connect(updateFreeKillStatus)

local function showFreeKillIgnoreReason(show: boolean): ()
    local hasReason = not not LocalRoundInfo.FreeKill()
    local hasCharacter = not not LocalCharacter.Character()
    statusEffects.FreeKill.Visible = hasCharacter and (show or hasReason)
end

ClientInventory.EquippedItem:Connect(function(item)
    if not item then
        return showFreeKillIgnoreReason(false)
    end

    local role = participant.Role()
    if item.IsSuspicious and not role.Definition.CanDoSuspiciousActions then
        return showFreeKillIgnoreReason(true)
    end

    showFreeKillIgnoreReason(false)
end)

return nil