local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local TextChatService = game:GetService("TextChatService")
local RoundHandler = require(ServerScriptService.RoundHandler)

local module = {}

-- For some fucking reason TT2 chat colours don't match the brick colours available, because fuck you?
local function remapColor(color: string): BrickColor
	if BrickColor[color] then
		return BrickColor[color]()
	end

	local splitsAt = -1
	for i, char in color:split("") do
		if i == 1 then
			continue
		end
		if char == char:upper() and char ~= char:lower() then
			splitsAt = i
			break
		end
	end

	if splitsAt == -1 then
		return BrickColor.new(color :: "Bright yellow")
	end

	local new = (color:sub(1, splitsAt - 1)) .. " " .. (color:sub(splitsAt, -1):lower())
	return BrickColor.new(new :: "Bright yellow")
end

function module.GameMessage(self, message: string, colour: string?, _: nil, player: Player?): ()
	local round = RoundHandler.GetRound()
	local brickColor = if colour then remapColor(colour) else nil
	local formattedMessage = if brickColor then `<font color='#{brickColor.Color:ToHex()}'>{message}</font>` else message
	round:SendMessage(player or Players:GetPlayers(), formattedMessage, "Chat")
end

local playerChatted = Instance.new("BindableEvent")
module.PlayerChatted = playerChatted.Event

local RBXGeneral = TextChatService:WaitForChild("TextChannels"):WaitForChild("RBXGeneral") :: TextChannel
RBXGeneral.ShouldDeliverCallback = function(message: TextChatMessage): ()
	playerChatted:Fire(Players:GetPlayerByUserId(message.TextSource.UserId), message.Text)
	return true -- lol! if this doesn't return a truthy value then the message don't get sent 😢
end

return module