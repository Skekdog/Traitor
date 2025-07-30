local ServerScriptService = game:GetService("ServerScriptService")
local TextChatService = game:GetService("TextChatService")
local RoundHandler = require(ServerScriptService.RoundHandler)

local module = {}

function module.GameMessage(self, message: string, colour: string, _, player: Player): ()
	local round = RoundHandler.GetRound()
	local brickColor = BrickColor.new(colour :: "Bright yellow")
	round:SendMessage(player, `<font color='#{brickColor.Color:ToHex()}'>{message}</font>`, "Chat")
end

local playerChatted = Instance.new("BindableEvent")
module.PlayerChatted = playerChatted.Event

TextChatService.MessageReceived:Connect(function(message: TextChatMessage): ()
	playerChatted:Fire(message.TextSource, message.Text)
end)

return module