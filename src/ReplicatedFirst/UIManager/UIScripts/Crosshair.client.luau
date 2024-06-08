local UIS = game:GetService("UserInputService")
local UIManager = require(script.Parent.Parent)
UIManager.WaitForUI("Crosshair"):ToggleVisible(UIS.TouchEnabled and not UIS.MouseEnabled)
local mouse = game:GetService("Players").LocalPlayer:GetMouse()
mouse.Icon = "rbxassetid://10801958931"