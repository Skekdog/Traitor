local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.Shared.RoundRule.Types)
local DynamicValue = require(ReplicatedStorage.Shared.Util.DynamicValue)
local HighlightPlayer = require(script.Parent.HighlightPlayer)
local LocalParticipantInfo = require(script.Parent.LocalParticipantInfo)

local module = {}

local activeConnections: {[string]: DynamicValue.Connection<Types.Role>} = {}
LocalParticipantInfo.Participants:Connect(function(participants)
    for name, v in participants do
        if name == Players.LocalPlayer.Name then
            continue
        end

        if activeConnections[name] then
            activeConnections[name]:Disconnect()
        end

        activeConnections[name] = v.Role:Connect(function(role)
            local player = Players:FindFirstChild(name)
            if not player or not player:IsA("Player") then
                return
            end
            HighlightPlayer(player)
        end, true)
    end
end, true)

function module.Reset(): ()
	for _, v in CollectionService:GetTagged("AllyMarker") do
		v:Destroy()
	end
end

return module