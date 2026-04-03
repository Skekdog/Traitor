local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local GetRemote = require(ReplicatedStorage.API.GetRemote)
local Replication = require(ReplicatedStorage.Shared.RoundRule.Replication)

local Message = {}

export type ReplicationTarget = Player | {[any]: Player} | "All"

local IS_SERVER = RunService:IsServer()

local notication = GetRemote("Notification", script)
function Message.Notification(message: string, isTeamMessage: boolean?, target: ReplicationTarget?): ()
	if IS_SERVER then
		assert(target, "Using Message on the server must specify a target")
		return Replication.FireToTargets(notication, target, message, isTeamMessage)
	end
	assert(target, "Using Message on the client must not specify a target")

	local ShowMessage = require(ReplicatedStorage.Shared.Interface.Util.ShowMessage)
	ShowMessage(message, if isTeamMessage then "Team" else "All")
end

if not IS_SERVER then
	notication.OnClientEvent:Connect(Message.Notification)
end

local popup = GetRemote("Popup", script)
function Message.Popup(message: string, target: ReplicationTarget?): ()
	if IS_SERVER then
		assert(target, "Using Message on the server must specify a target")
		return Replication.FireToTargets(popup, target, message)
	end

	local ShowAlert = require(ReplicatedStorage.Shared.Interface.Util.ShowAlert)
	ShowAlert(message)
end

if not IS_SERVER then
	popup.OnClientEvent:Connect(Message.Popup)
end

local chat = GetRemote("Chat", script)
function Message.Chat(message: string, target: ReplicationTarget?): ()
	if IS_SERVER then
		assert(target, "Using Message on the server must specify a target")
		return Replication.FireToTargets(chat, target, message)
	end
	assert(target, "Using Message on the client must not specify a target")

	local ShowMessage = require(ReplicatedStorage.Shared.Interface.Util.ShowMessage)
	ShowMessage(message, "Chat")
end

if not IS_SERVER then
	chat.OnClientEvent:Connect(Message.Chat)
end

export type ScreenMessageFormat = "Standard" | "Error" | "Info" | "Success" | "Warn"

local screen = GetRemote("Screen", script)
function Message.Screen(message: string, format: ScreenMessageFormat, overrides: {LabelProperties: {[string]: any}}?, target: ReplicationTarget?): ()
	if IS_SERVER then
		assert(target, "Using Message on the server must specify a target")
		return Replication.FireToTargets(screen, target, message, format, overrides)
	end
	assert(target, "Using Message on the client must not specify a target")

	local ScreenMessage = require(ReplicatedStorage.Shared.Interface.Util.ScreenMessage)
	ScreenMessage(format, message, overrides)
end

if not IS_SERVER then
	screen.OnClientEvent:Connect(Message.Screen)
end

return table.freeze(Message)