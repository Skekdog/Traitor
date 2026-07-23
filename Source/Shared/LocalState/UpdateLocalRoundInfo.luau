local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalRoundInfo = require(script.Parent.LocalRoundInfo)

local replicatedData = ReplicatedStorage.Shared.RoundRule.ReplicatedData
local remotes = ReplicatedStorage.Shared.RoundRule.Remotes

local function updateGamemode(name: string?)
    if not name then
        LocalRoundInfo.Gamemode:SetValue()
        return
    end

    local isSucky = false

    local object = ReplicatedStorage.Shared.GameDefinition.Gamemodes:FindFirstChild(name)
    if not object then
        local map = LocalRoundInfo.Map()
        if map and map.Structure:FindFirstChild("Bosses") then
            object = (map.Structure.Bosses :: Instance):FindFirstChild(name)
            isSucky = true
        end
    end

    if object then
        local ret = (require)(object)
        if isSucky then
            LocalRoundInfo.Gamemode:SetValue(ret.Gamemode)
        else
            LocalRoundInfo.Gamemode:SetValue(ret)
        end
    else
        LocalRoundInfo.Gamemode:SetValue()
    end
end

updateGamemode(replicatedData:GetAttribute("Gamemode") :: string?)
remotes.Gamemode.OnClientEvent:Connect(updateGamemode)

return nil