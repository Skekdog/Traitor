local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ConfirmationPrompt = require(script.Parent.ConfirmationPrompt)

local remote = ReplicatedStorage.RoundRule.Remotes.SlayVote

local function prompt(against: string): ()
	ConfirmationPrompt(`You've just been RDM'ed by {against}! Because of this, you may vote to slay them.`, function(response: boolean)
		if response then
			remote:FireServer(against)
		end
	end)
end

remote.OnClientEvent:Connect(prompt)

return nil