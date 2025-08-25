local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local TextChatService = game:GetService("TextChatService")
local RoundHandler = require(ServerScriptService.RoundHandler)

local module = {}

function module.GameMessage(self, message: string, colour: string?, _, player: Player?): ()
	local round = RoundHandler.GetRound()
	local brickColor = colour and BrickColor.new(colour :: "Bright yellow")
	local formattedMessage = if brickColor then `<font color='#{brickColor.Color:ToHex()}'>{message}</font>` else message
	round:SendMessage(player or Players:GetPlayers(), formattedMessage, "Chat")
end

local playerChatted = Instance.new("BindableEvent")
module.PlayerChatted = playerChatted.Event

local RBXGeneral = TextChatService:WaitForChild("TextChannels"):WaitForChild("RBXGeneral") :: TextChannel
RBXGeneral.ShouldDeliverCallback = function(message: TextChatMessage): ()
	playerChatted:Fire(Players:GetPlayerByUserId(message.TextSource.UserId), message.Text)
end

return module