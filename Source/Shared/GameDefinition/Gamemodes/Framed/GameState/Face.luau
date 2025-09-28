local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.API.Types)

local FACES = {
	7058424,
	129157225,
	8056256,
	84765513,
	46191660,
	63493270,
	5593531733,
	63493189,
	63495329,
	19575865,
	33082306,
	48292410,
	2832230508,
	7863486,
	10747371,
	112805849,
	105746136,
	63493134,
	7863475,
	63760920,
	63495374,
	13189919,
	22146172,
	45885464,
	62550584,
	37400348,
	90272454,
	53769373,
	63493113,
	125441679,
	63493236,
	32012505,
	26435239,
	78206301,
	22556555,
	26449032,
	221063187,
	146653098,
	145716782,
	128276790,
	10556873,
	142235495,
	136512852,
	89386931,
	127040214,
	10893796,
	123014611,
	30192078,
	210559531,
	277519039,
	147322184,
	210559168,
	22566590,
	279643280,
	274530252,
	227600967,
	210559322,
	169116959,
	162136179,
	149118410,
	33469110,
	205515840,
	205517873,
	98241173,
	3739559467,
	150201399,
	25357806,
	30559789,
	8075700,
	37635390,
	74988017,
	6208303435,
	12451696,
	850678575,
	3945036190,
	33545586,
}

local function popRandomFace(faces: {number}): string
	return "rbxassetid://" .. (table.remove(faces, math.random(#faces)) or error("No available faces"))
end

local function GetFaceInstance(char: Model): Decal?
	local head = char:FindFirstChild("Head")
	if not head or not head:IsA("BasePart") then
		return nil
	end

	local face = head:FindFirstChild("face")
	if not face or not face:IsA("Decal") then
		return nil
	end

	return face
end

local function FaceIt(round: Types.Round, char: Model): ()
	local face = GetFaceInstance(char)
	if not face then
		return
	end

	local faces = round.Extras.Faces or table.clone(FACES)
	round.Extras.Faces = faces
	face.Texture = popRandomFace(faces)
end

return {
	FaceIt = FaceIt,
	GetFaceInstance = GetFaceInstance,
}