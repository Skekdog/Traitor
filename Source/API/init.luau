local API = {}

API.Combat = function() return require(script.Combat) end
API.GetMapThing = function() return require(script.GetMapThing) end
API.GetParticipant = function() return require(script.GetParticipant) end
API.GetRound = function() return require(script.GetRound) end
API.Notification = function() return require(script.Notification) end
API.PlaySound = function() return require(script.PlaySound) end
API.TextColor = function() return require(script.TextColor) end

return API