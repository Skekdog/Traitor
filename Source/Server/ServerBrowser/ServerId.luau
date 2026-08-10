local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

return if RunService:IsStudio() then HttpService:GenerateGUID(false) else game.JobId