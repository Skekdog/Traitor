local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UIAnimation = require(ReplicatedStorage.Shared.Interface.UILib.UIAnimation)
local UIManager = require(ReplicatedStorage.Shared.Interface.UILib.UIManager)

local roundInfo = UIManager.WaitForUI("RoundInfo").Object :: typeof(UIManager.UnregisteredUIs.RoundInfo)
local ammoBar = roundInfo.Frame.AmmoBar

return function(current: number, magazineSize: number, reserve: number): ()
    ammoBar.AmmoLabel.Text = `{current} / {magazineSize} + {reserve}`
    UIAnimation.Slider(ammoBar.Background, nil, current, magazineSize)
end
