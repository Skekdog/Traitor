local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UIAnimation = require(ReplicatedStorage.Shared.Interface.UILib.UIAnimation)
local UIManager = require(ReplicatedStorage.Shared.Interface.UILib.UIManager)

local EquipmentMenu = {}

local ui = UIManager.WaitForUI("Equipment") :: UIManager.UI & {Object: typeof(UIManager.UnregisteredUIs["Equipment"])}

local currentPage: GuiObject?

function EquipmentMenu.AddPage(page: GuiObject): ()
	local tabButton = ui.Object.TabHolder.TabTemplate:Clone()
	tabButton.Name = page.Name
	tabButton.Text = page.Name
	tabButton.Visible = true
	tabButton.Parent = ui.Object.TabHolder.Tabs :: any

	page.AnchorPoint = Vector2.new(0.5, 0)
	page.Position = UDim2.fromScale(0.5, 0)
	page.LayoutOrder = #ui.Object.Page:GetChildren()
	page.Visible = false

	if not currentPage then
		page.Visible = true
		currentPage = page
	end

	page.Parent = ui.Object.Page

	tabButton.Activated:Connect(function()
		if page == currentPage then
			return
		end
		assert(currentPage, "No current page")
		UIAnimation.TransitionUIPage(currentPage, page, UDim2.fromScale(0.5, 0))
		currentPage = page
	end)
end

function EquipmentMenu.RemovePage(page: GuiObject): ()
	local tabButton = ui.Object.TabHolder.Tabs:FindFirstChild(page.Name)
	if tabButton then
		tabButton:Destroy()
	end

	if currentPage == page then
		local nextPage: GuiObject?
		for _, p in ui.Object.Page:GetChildren() do
			if p:IsA("GuiObject") then
				nextPage = p
				break
			end
		end

		if nextPage then
			UIAnimation.TransitionUIPage(page, nextPage, UDim2.fromScale(0.5, 0))
		end

		currentPage = nil
	end

	page.Parent = nil
end

return EquipmentMenu