local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Types = require(ReplicatedStorage.API.Types)
local GetRemote = require(ReplicatedStorage.Shared.GameDefinition.Items.Common.GetRemote)

export type HighlightContext = "Mark" | "RedHanded" | "Kill"

local remote = GetRemote("HighlightCharacter")

local function makeHighlight(instance: Instance, enable: boolean, context: HighlightContext): ()
	local highlight = instance:FindFirstChild("FramedHighlight_" .. context)
	assert(not highlight or highlight:IsA("Highlight"), "FramedHighlight must be a Highlight")

	if not highlight then
		local newHighlight =  Instance.new("Highlight")
		newHighlight.Adornee = instance
		newHighlight.FillColor = Color3.fromRGB(255, 0, 0)
		newHighlight.OutlineColor = Color3.fromRGB(255, 255, 255)
		newHighlight.FillTransparency = 0.5
		newHighlight.OutlineTransparency = 0.5
		newHighlight.DepthMode = if context == "RedHanded" then Enum.HighlightDepthMode.Occluded else Enum.HighlightDepthMode.AlwaysOnTop
		newHighlight.Name = "FramedHighlight_" .. context
		newHighlight.Parent = instance
		highlight = newHighlight
	end
	assert(highlight, "Highlight must exist")

	highlight.Enabled = enable
end

local function HighlightCharacter(char: Model, enable: boolean, context: HighlightContext, to: {Types.Participant}): ()
	if RunService:IsServer() then
		for _, participant in to do
			remote:FireClient(participant.Player, char, enable, context)
		end
		return
	end

	makeHighlight(char, enable, context)
end

if RunService:IsClient() then
	remote.OnClientEvent:Connect(function(char: Model, enable: boolean, context: HighlightContext)
		makeHighlight(char, enable, context)
	end)
end

return HighlightCharacter