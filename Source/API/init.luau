local RunService = game:GetService("RunService")

type APIReturn = {
	Combat: typeof(require(script.Combat)),
	GetMapThing: typeof(require(script.GetMapThing)),
	GetParticipant: typeof(require(script.GetParticipant)),
	GetRound: typeof(require(script.GetRound)),
	Notification: typeof(require(script.Notification)),
	PlaySound: typeof(require(script.PlaySound)),
	TextColor: typeof(require(script.TextColor)),
	Items: typeof(require(script.Items)),
	GetRemote: typeof(require(script.GetRemote)),
}

if RunService:IsClient() then
	return {
		GetMapThing = require(script.GetMapThing),
		Notification = require(script.Notification),
		PlaySound = require(script.PlaySound),
		TextColor = require(script.TextColor),
		GetRemote = require(script.GetRemote),
	} :: APIReturn
end

return {
	Combat = require(script.Combat),
	GetMapThing = require(script.GetMapThing),
	GetParticipant = require(script.GetParticipant),
	GetRound = require(script.GetRound),
	PlaySound = require(script.PlaySound),
	TextColor = require(script.TextColor),
	Items = require(script.Items),
	GetRemote = require(script.GetRemote),
} :: APIReturn