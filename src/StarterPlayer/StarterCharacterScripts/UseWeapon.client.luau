local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ControlManager = require(ReplicatedFirst.ControlManager)
ControlManager.Register(actionName, createTouchButton, callback)