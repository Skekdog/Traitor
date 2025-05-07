local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ConfirmationPrompt = require(ReplicatedStorage.Shared.Interface.Util.ConfirmationPrompt)

local remote = ReplicatedStorage.Shared.RoundRule.Remotes.SlayVote

local function prompt(against: string): ()
	ConfirmationPrompt(`You've just been RDM'ed by {against}! Because of this, you may vote to slay them.`, function(response: boolean)
		if response then
			remote:FireServer(against)
		end
	end)
end

remote.OnClientEvent:Connect(prompt)

return nil