local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalRoundInfo = require(script.Parent.LocalRoundInfo)
return function(target: string): ()
    if LocalRoundInfo.DNACharge < 1000 then
        return
    end
    
    local old = workspace:FindFirstChild("DNAPoint")
    if old then
        old:Destroy()
    end

    local model = (workspace.Characters:FindFirstChild(target) or workspace.Corpses:FindFirstChild(target)) :: Model

    local position = if model then model:GetPivot() else CFrame.new()
    local distance = Players.LocalPlayer:DistanceFromCharacter(position.Position)

    if target then
        LocalRoundInfo.DNACharge = math.max(0, LocalRoundInfo.DNACharge - distance / 2)
    end

    local clone = ReplicatedStorage.RadarPoint:Clone()

    local highlight = clone.Highlight
    highlight.FillColor = Color3.new(0.466667, 0.980392, 1.000000)
    highlight.OutlineColor = Color3.new(0.403922, 0.435294, 1.000000)

    local label = clone.RadarPoint.TextLabel
    label.TextColor3 = Color3.new(0.403922, 0.435294, 1.000000)
    clone.RadarPoint.ImageLabel.ImageColor3 = Color3.new(0.403922, 0.435294, 1.000000)

    clone:PivotTo(position)
    label.Text = tostring(math.round(distance))
    clone.RadarPoint.Enabled = true
    clone.Name = "DNAPoint"
    clone.Parent = workspace
end