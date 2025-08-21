local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.Shared.RoundRule.Types)
local DynamicValue = require(ReplicatedStorage.Shared.Util.DynamicValue)
local HighlightPlayer = require(script.Parent.HighlightPlayer)
local LocalParticipantInfo = require(script.Parent.LocalParticipantInfo)

local module = {}

local function rehighlightPlayer(name: string): ()
    local player = Players:FindFirstChild(name)
    if not player or not player:IsA("Player") or not player.Character then
        return
    end

    local icon = player.Character:FindFirstChild("RoleIcon")
    if icon then
        icon:Destroy()
    end

    local highlight = player.Character:FindFirstChild("Highlight")
    if highlight then
        highlight:Destroy()
    end

    HighlightPlayer(player)
end

local function rehighlight(names: {string}): ()
    for _, name in names do
        rehighlightPlayer(name)
    end
end

local cons: {[string]: DynamicValue.Connection<Types.Role>} = {}

LocalParticipantInfo.Participants:Connect(function(participants)
    local names: {string} = {}
    for name, v in participants do
        table.insert(names, name)
        cons[name] = v.Role:Connect(function(role)
            if name == Players.LocalPlayer.Name then
                rehighlight(names)
            else
                rehighlightPlayer(name)
            end
        end, true)
    end

    for name in cons do
        if not table.find(names, name) then
            cons[name]:Disconnect()
        end
    end
end, true)

function module.Reset(): ()
	for _, v in CollectionService:GetTagged("AllyMarker") do
		v:Destroy()
	end
end

return module