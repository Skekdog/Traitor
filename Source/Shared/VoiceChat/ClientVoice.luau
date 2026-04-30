local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GetRemote = require(ReplicatedStorage.API.GetRemote)
local Types = require(ReplicatedStorage.API.Types)
local ControlManager = require(ReplicatedStorage.Shared.Controls.ControlManager)

local VoiceChatClient = {}

local remote = GetRemote("TeamVoice", ReplicatedStorage.Remotes.ClientServer)

function VoiceChatClient.AllowTeamVoice(role: Types.RoleDefinition, status: Types.ParticipantStatus | "Spectating"): ()
	local allow = (role.CanTeamChat and status == "Alive") or false
	if allow then
		ControlManager.Register("Team Voice", function(_, state)
			remote:FireServer(state == Enum.UserInputState.Begin)
			return Enum.ContextActionResult.Pass
		end)
	else
		ControlManager.Unregister("Team Voice")
	end
end

return table.freeze(VoiceChatClient)