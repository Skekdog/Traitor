local ReplicatedStorage = game:GetService("ReplicatedStorage")
local wm = require(game.ServerScriptService.WeaponModule)

local si = ReplicatedStorage.ServerInterconnect
si.ExplosiveBarrel.Event:Connect(function(part:BasePart,plr:Player?)
	if part then
		wm.CreateExplosion(plr,part.Position,15,{["Base"]=200,["Falloff"]=0,["FalloffEnd"]=15,["FalloffStart"]=5},50)
	end
end)