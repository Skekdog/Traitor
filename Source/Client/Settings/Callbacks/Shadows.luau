local Lighting = game:GetService("Lighting")

return function(name: string, value: boolean): ()
	Lighting.GlobalShadows = value
end