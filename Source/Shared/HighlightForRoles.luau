local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local HighlightPlayer = require(script.Parent.HighlightPlayer)
local LocalRoundInfo = require(script.Parent.LocalRoundInfo)

local module = {}

LocalRoundInfo.PlayerRoles:Connect(function(roles)
    for _, v in Players:GetPlayers() do
        if v ~= Players.LocalPlayer then
            HighlightPlayer(v)
        end
    end
end, true)

function module.Reset(): ()
	for _, v in CollectionService:GetTagged("AllyMarker") do
		v:Destroy()
	end
end

return module