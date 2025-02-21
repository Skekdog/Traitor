local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UIManager = require(ReplicatedStorage.UIManager)

return function(name: string, value: boolean): ()
	local sidebar = UIManager.WaitForUI("Sidebar")
    if sidebar then
        sidebar:ToggleVisible(value)
    end
end
