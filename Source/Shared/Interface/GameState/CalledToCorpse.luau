local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CreateRadarPoint = require(ReplicatedStorage.API.CreateRadarPoint)

ReplicatedStorage.Shared.RoundRule.Remotes.CallToCorpse.OnClientEvent:Connect(function(corpse: Model): ()
	CreateRadarPoint(corpse:GetPivot(), Color3.fromRGB(0, 110, 255), "CallToCorpse" .. corpse.Name)
end)

return nil