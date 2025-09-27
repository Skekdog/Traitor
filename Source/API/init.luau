local RunService = game:GetService("RunService")

type APIReturn = {
	Combat: typeof(require(script.Combat)),
	GetMapObject: typeof(require(script.GetMapObject)),
	GetParticipant: typeof(require(script.GetParticipant)),
	GetRound: typeof(require(script.GetRound)),
	Notification: typeof(require(script.Notification)),
	PlaySound: typeof(require(script.PlaySound)),
	TextColor: typeof(require(script.TextColor)),
	StandardGame: typeof(require(script.StandardGame)),
	GetRemote: typeof(require(script.GetRemote)),
}

if RunService:IsClient() then
	return {
		GetMapObject = require(script.GetMapObject),
		Notification = require(script.Notification),
		PlaySound = require(script.PlaySound),
		TextColor = require(script.TextColor),
		GetRemote = require(script.GetRemote),
	} :: APIReturn
end

return {
	Combat = require(script.Combat),
	GetMapObject = require(script.GetMapObject),
	GetParticipant = require(script.GetParticipant),
	GetRound = require(script.GetRound),
	PlaySound = require(script.PlaySound),
	TextColor = require(script.TextColor),
	StandardGame = require(script.StandardGame),
	GetRemote = require(script.GetRemote),
} :: APIReturn