local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ItemHint = require(ReplicatedStorage.Shared.Controls.ItemHint)

return function(name: string, value: boolean): ()
	if not value then
        ItemHint()
    end
end
