local ServerScriptService = game:GetService("ServerScriptService")
local RoundHandler = require(ServerScriptService.RoundHandler)

local module = {}

function module.GameMessage(self, message: string, colour: string, _, player: Player): ()
	local round = RoundHandler.GetRound()
	local brickColor = BrickColor.new(colour :: "Bright yellow")
	round:SendMessage(player, `<font color='#{brickColor.Color:ToHex()}'>{message}</font>`, "Chat")
end

module.PlayerChatted = nil

return module