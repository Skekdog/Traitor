local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CorpseInfo = require(script.Parent.CorpseInfo)
local LocalRoundInfo = require(script.Parent.LocalRoundInfo)

local function ViewCorpse(body: Model): ()
	local corpse = LocalRoundInfo.GetCorpse(body.Name)
	if not corpse then
		corpse = ReplicatedStorage.ClientServer.GetCorpseInfo:InvokeServer(body)
		if not corpse then
			return
		end
	end

	assert(corpse)

	CorpseInfo(corpse)
end

return ViewCorpse