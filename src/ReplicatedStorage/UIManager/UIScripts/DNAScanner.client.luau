error("DNA Scanner is disabled")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UIManager = require(script.Parent.Parent)
local LocalRoundInfo = require(script.Parent.Parent.Parent.LocalRoundInfo)
local TryPingDNA = require(script.Parent.Parent.Parent.TryPingDNA)
local UIAnimation = require(script.Parent.Parent.Parent.UIAnimation)

local ui = UIManager.WaitForUI("DNAScanner").Object :: typeof(UIManager.UnregisteredUIs.DNAScanner)

local selected: string?
local autoScan = true

RunService.PreRender:Connect(function(dt: number)
    LocalRoundInfo.DNACharge = math.min(1000, LocalRoundInfo.DNACharge + dt * 30)

    if selected and autoScan then
        TryPingDNA(selected)
    end

    local charge = math.round(LocalRoundInfo.DNACharge)
    ui.DNAChargeBar.ChargeLabel.Text = (charge / 10) .. "%"
    ui.DNAChargeBar.Background.Size = UDim2.fromScale(charge / 1000, 1)
end)

ui.ScanButton.MouseButton1Click:Connect(function()
    if selected then
        TryPingDNA(selected)
    end
end)

ui.AutoScanButton.MouseButton1Click:Connect(function()
    autoScan = not autoScan
    UIAnimation.TransitionSwitch(ui.AutoScanButton.Value, autoScan)
end)

ReplicatedStorage:WaitForChild("ServerClient").AcquireDNASample.OnClientEvent:Connect(function(model: Model, name: string)
    local sample = ui.DefaultSample:Clone()
    sample.Name = name
    sample.Visible = true
    sample.Parent = ui.Samples

    if not selected then
        sample.UIStroke.Enabled = true
        selected = name
    end

    sample.MouseButton1Click:Connect(function()
        if selected == name then
            sample.UIStroke.Enabled = false
            selected = nil
            return
        end
        for _, v in ui.Samples:GetChildren() do
            local uiStroke = v:FindFirstChildOfClass("UIStroke")
            if uiStroke then
                uiStroke.Enabled = false
            end
        end

        sample.UIStroke.Enabled = true
        selected = name
    end)
end)

LocalRoundInfo.Listen("IsSpectating", function()
    for _, v in ui.Samples:GetChildren() do
        if v:IsA("ImageButton") then
            v:Destroy()
        end
    end

    local old = workspace:FindFirstChild("DNAPoint")
    if old then
        old:Destroy()
    end

    selected = nil
    LocalRoundInfo.DNACharge = 1000
end)
