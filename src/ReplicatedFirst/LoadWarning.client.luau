local Players = game:GetService("Players")
local UIManager = require(script.Parent.UIManager)

local unregisteredUIs = UIManager.UnregisteredUIs
local plr = Players.LocalPlayer

local start = os.time()
local found = false
task.spawn(function()
    UIManager.WaitForUI("Crosshair", true)
    found = true
end)

local special = plr.PlayerGui:FindFirstChild("Special") :: any

while not found do
    if (os.time() - start > 5) and unregisteredUIs:FindFirstChild("LoadWarning") then
        unregisteredUIs.LoadWarning.Parent = special
    end
    task.wait()
end

local warning = special:FindFirstChild("LoadWarning")
if warning then
    warning:Destroy()
end