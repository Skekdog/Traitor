local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local IS_SERVER = RunService:IsServer()
local id = 0

return function(alert: string, player: Player?): ()
    if IS_SERVER then
        assert(player)
        ReplicatedStorage.ServerClient.SendAlert:FireClient(player, alert)
    else
        id += 1
        local lastId = id

        local UIManager = require(script.Parent.UIManager)
        local alertUI = UIManager.WaitForUI("Alert") :: UIManager.UI & {Object: typeof(UIManager.UnregisteredUIs.Alert)}

        local function show(): ()
            alertUI.Object.Text = alert
            alertUI:ToggleVisible(true)
            task.delay(3, function()
                if id == lastId then
                    alertUI:ToggleVisible(false)
                end
            end)
        end

        if alertUI.Visible then
            alertUI:ToggleVisible(false, nil, show)
        else
            show()
        end
    end
end
