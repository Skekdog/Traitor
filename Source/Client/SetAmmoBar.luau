local UIAnimation = require(script.Parent.UIAnimation)
local UIManager = require(script.Parent.UIManager)

local roundInfo = UIManager.WaitForUI("RoundInfo").Object :: typeof(UIManager.UnregisteredUIs.RoundInfo)
local ammoBar = roundInfo.Frame.AmmoBar

return function(current: number, magazineSize: number, reserve: number): ()
    ammoBar.AmmoLabel.Text = `{current} / {magazineSize} + {reserve}`
    UIAnimation.Slider(ammoBar.Background, nil, current, magazineSize)
end
