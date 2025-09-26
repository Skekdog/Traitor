local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local GetAliveRoles = require(script.Parent.GetAliveRoles)
local HighlightCharacter = require(script.Parent.HighlightCharacter)
local Types = require(ReplicatedStorage.API.Types)
local GetRemote = require(ReplicatedStorage.Shared.GameDefinition.Items.Common.GetRemote)

local RedHanded = {}

local remote = GetRemote("RedHanded")

local RED_HANDED_DURATION = 5

function RedHanded.Start(participant: Types.Participant): ()
	local id = GetAliveRoles(participant.Round, {"Police", "Undercover", "Framed"})

	local char = participant:GetCharacter()
	if char then
		HighlightCharacter(char, true, "RedHanded", id)
	end

	remote:FireClient(participant.Player)
	participant.Extras.FramedRedHanded = id
end

function RedHanded.Stop(participant: Types.Participant): ()
	local id = participant.Extras.FramedRedHanded
	if not id then
		return
	end

	remote:FireClient(participant.Player, true)

	task.delay(RED_HANDED_DURATION, function()
		if participant.Extras.FramedRedHanded ~= id then
			return
		end

		id = participant.Extras.FramedRedHanded
		participant.Extras.FramedRedHanded = nil

		local char = participant:GetCharacter()
		if char then
			HighlightCharacter(char, false, "RedHanded", id)
		end
	end)
end

if RunService:IsClient() then
	local UIManager = require(ReplicatedStorage.Shared.Interface.UILib.UIManager)
	local ui = UIManager.RegisterUI(script.Parent.FramedRedHandedUI) :: UIManager.UI & {Object: typeof(script.Parent.FramedRedHandedUI)}

	local currentTween: Tween?
	remote.OnClientEvent:Connect(function(stop: true?)
		if currentTween then
			currentTween:Cancel()
		end

		if not stop then
			ui.Object.Frame.Size = UDim2.fromScale(1, 0.25)
			ui:ToggleVisible(true)
			return
		end

		currentTween = TweenService:Create(ui.Object.Frame, TweenInfo.new(RED_HANDED_DURATION, Enum.EasingStyle.Linear), { Size = UDim2.fromScale(0, 0.25) })
		assert(currentTween)

		currentTween.Completed:Connect(function(state)
			if state ~= Enum.PlaybackState.Completed then
				return
			end
			ui:ToggleVisible(false)
		end)
		currentTween:Play()
	end)
end

return RedHanded