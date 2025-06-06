local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UIManager = require(ReplicatedStorage.Shared.Interface.UILib.UIManager)
local Types = require(ReplicatedStorage.Shared.RoundRule.Types)

local MAX_DAMAGE = 60
local MIN_DAMAGE = 1

local MIN_TRANSPARENCY = 0.5
local TRANSITION_INFO = TweenInfo.new(0.75, Enum.EasingStyle.Linear)

local DAMAGE_COLOUR = Color3.new(1, 0, 0)
local DROWN_DAMAGE_COLOUR = Color3.new(0, 0, 1)

local frame = Instance.new("Frame")
frame.Size = UDim2.fromScale(1, 1)
frame.BackgroundTransparency = 1
frame.Name = "DamageFlash"
frame:SetAttribute("Layer", "HUD")
frame:SetAttribute("IgnoreInset", true)

UIManager.RegisterUI(frame):ToggleVisible(true)

ReplicatedStorage.Shared.RoundRule.Remotes.DamageTaken.OnClientEvent:Connect(function(amount: number, kind: Types.GeneralDamageSource | string)
	if amount < MIN_DAMAGE then
		return
	end

	frame.BackgroundColor3 = if kind == "Drown" then DROWN_DAMAGE_COLOUR else DAMAGE_COLOUR

	local factor = math.min(amount / MAX_DAMAGE, 1)
	frame.BackgroundTransparency = math.max(MIN_TRANSPARENCY, 1 - factor)

	TweenService:Create(frame, TRANSITION_INFO, {BackgroundTransparency = 1}):Play()
end)

return nil