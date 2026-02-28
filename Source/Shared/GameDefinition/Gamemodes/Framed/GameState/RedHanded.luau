local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local GetRemote = require(ReplicatedStorage.API.GetRemote)
local GetAliveRoles = require(script.Parent.Parent.Roles.GetAliveRoles)
local HighlightCharacter = require(script.Parent.HighlightCharacter)
local Types = require(ReplicatedStorage.API.Types)

local RedHanded = {}

local remote = GetRemote("RedHanded", script)

local RED_HANDED_DURATION = 3.5

function RedHanded.Start(participant: Types.Participant): ()
	if RedHanded.IsPermanent(participant) then
		return
	end

	local id = GetAliveRoles(participant.Round, {"Police", "Undercover"})

	local char = participant:GetCharacter()
	if char then
		HighlightCharacter(char, true, "RedHanded", id)
	end

	remote:FireClient(participant.Player)
	participant.Extras.FramedRedHanded = id
end

function RedHanded.StopImmediately(participant: Types.Participant): ()
	remote:FireClient(participant.Player, false)
end

function RedHanded.Stop(participant: Types.Participant): ()
	if RedHanded.IsPermanent(participant) then
		return
	end

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

function RedHanded.IsPermanent(participant: Types.Participant): boolean
	return participant.Extras.PermanentRedHanded == true and participant:IsAlive()
end

function RedHanded.SetPermanent(participant: Types.Participant): ()
	participant.Extras.PermanentRedHanded = true
	participant.Extras.FramedRedHanded = nil
	remote:FireClient(participant.Player)
end

function RedHanded.IsRedHanded(participant: Types.Participant): boolean
	return RedHanded.IsPermanent(participant) or participant.Extras.FramedRedHanded ~= nil
end

if RunService:IsClient() then
	local UIManager = require(ReplicatedStorage.Shared.Interface.UILib.UIManager)
	local ui = UIManager.RegisterUI(ReplicatedStorage.Assets.Gamemode.Framed.UI.FramedRedHandedUI) :: UIManager.UI & {Object: typeof(ReplicatedStorage.Assets.Gamemode.Framed.UI.FramedRedHandedUI)}

	local currentTween: Tween?
	remote.OnClientEvent:Connect(function(stop: true?)
		if currentTween then
			currentTween:Cancel()
		end

		if not stop then
			ui.Object.Frame.Size = UDim2.fromScale(1, 0.25)
			ui:ToggleVisible(stop == nil)
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