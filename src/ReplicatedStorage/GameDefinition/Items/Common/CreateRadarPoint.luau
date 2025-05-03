local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local radarPoint = ReplicatedStorage.RadarPoint

type RadarPoint = typeof(radarPoint)

local function CreateRadarPoint(cFrame: CFrame, colour: Color3, name: string?): RadarPoint
	local noZRot = CFrame.Angles(cFrame.Rotation.X, cFrame.Rotation.Y, 0)
    cFrame = CFrame.new(cFrame.Position) * noZRot

    local clone = radarPoint:Clone()
    clone:PivotTo(cFrame)

    local ui = clone.RadarPoint
    ui.TextLabel.Text = tostring(math.round(Players.LocalPlayer:DistanceFromCharacter(cFrame.Position)))

	ui.ImageLabel.ImageColor3 = colour
	ui.TextLabel.TextColor3 = colour
	clone.Highlight.FillColor = colour
	clone.Highlight.OutlineColor = colour

    ui.Enabled = true

	clone.Name = name or "RadarPoint"

    clone.Parent = workspace.RadarPoints

	return clone
end

return CreateRadarPoint