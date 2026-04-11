local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Audio = require(ReplicatedStorage.API.Audio)
local LocalCharacter = require(ReplicatedStorage.Shared.Character.LocalCharacter)
local ControlManager = require(ReplicatedStorage.Shared.Controls.ControlManager)

local sound = Audio.MakeSound({
	Content = Content.fromAssetId(120344853558767),
})

local function tryGetAttachment(root: Instance): Attachment?
	local attachment = root:FindFirstChild("FlashlightAttachment")
	if not attachment then
		return nil
	end

	assert(attachment:IsA("Attachment"))

	return attachment
end

local function getOrCreateFlashlight(root: Instance): Light
	local attachment = tryGetAttachment(root)
	if not attachment then
		local newAttachment = Instance.new("Attachment")
		newAttachment.Name = "FlashlightAttachment"
		newAttachment.Parent = root
		attachment = newAttachment
	end
	assert(attachment and attachment:IsA("Attachment"))

	local light = attachment:FindFirstChild("Flashlight")
	if not light then
		local newLight = Instance.new("PointLight")
		newLight.Name = "Flashlight"
		newLight.Range = 12
		newLight.Brightness = 1
		newLight.Shadows = true
		newLight.Enabled = false
		newLight.Parent = attachment
		light = newLight
	end

	assert(light and light:IsA("Light"))

	return light
end

local enabled = false
local function enableFlashlight(doEnable: boolean?): Enum.ContextActionResult
	enabled = if typeof(doEnable) == "boolean" then doEnable else not enabled

	local root = LocalCharacter.RootPart()
	if not root then
		enabled = false
		return Enum.ContextActionResult.Pass
	end

	local light = getOrCreateFlashlight(workspace.CurrentCamera)
	light.Enabled = enabled

	Audio.Play2D(sound)

	return Enum.ContextActionResult.Pass
end

LocalCharacter.RootPart:Connect(function(part)
	if not part then
		ControlManager.Unregister("Flashlight")

		getOrCreateFlashlight(workspace.CurrentCamera).Enabled = false
		enabled = false

		return
	end

	if ControlManager.PreferredInput() == Enum.PreferredInput.Touch then
		return enableFlashlight(true)
	end

	ControlManager.Register("Flashlight", function()
		return enableFlashlight()
	end)
end, true)

ControlManager.PreferredInput:Connect(function(preferred)
	if preferred == Enum.PreferredInput.Touch then
		enableFlashlight(true)
	end
end, true)

return nil