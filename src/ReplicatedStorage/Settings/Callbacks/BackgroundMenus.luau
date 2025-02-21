local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UIManager = require(ReplicatedStorage.UIManager)

return function(name: string, value: string): ()
	UIManager.BackgroundMenuMode = value
end
