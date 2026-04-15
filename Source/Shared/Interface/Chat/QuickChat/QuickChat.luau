
local QuickChat = {}

QuickChat.Messages = {
	[1] = "Yes",
	[2] = "No",
	[3] = "Help",
	[4] = "I'm with {ID}",
	[5] = "I see {ID}",
	[6] = "{ID} is suspicious",
	[7] = "{ID} is evil",
	[8] = "{ID} is friendly",
	[9] = "Is anyone still alive",
}

function QuickChat.GetIdString(id: Model?): string
	local idString = "Nobody"

	if id then
		if id:HasTag("Corpse") then
			if id:GetAttribute("Unidentified") then
				idString = "An unidentified body"
			else
				idString = id.Name .. "'s corpse"
			end
		else
			idString = id.Name
		end
	end

	return idString
end

function QuickChat.FormatMessage(message: string, id: Model?): string
	return message:gsub("{ID}", QuickChat.GetIdString(id))
end

return table.freeze(QuickChat)