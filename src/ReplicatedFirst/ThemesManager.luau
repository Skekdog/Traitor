local CollectionService = game:GetService("CollectionService")

local module = {}

export type Theme = {
	Primary: Color3,
	Secondary: Color3,
	Text: Color3,
	TextStroke: Color3,
	UIStroke: Color3
}

module.Themes = {
	Light = {
		Primary = Color3.fromRGB(250, 250, 250),
		Secondary = Color3.fromRGB(210, 230, 230),
		Text = Color3.fromRGB(0, 0, 0),
		TextStroke = Color3.fromRGB(255, 255, 255),
		UIStroke = Color3.fromRGB(0, 0, 0),
	},
	Dark = {
		Primary = Color3.fromRGB(17, 17, 17),
		Secondary = Color3.fromRGB(34, 34, 34),
		Text = Color3.fromRGB(255, 255, 255),
		TextStroke = Color3.fromRGB(0, 0, 0),
		UIStroke = Color3.fromRGB(255, 255, 255),
	},
	Blue = {
		Primary = Color3.fromRGB(33, 66, 100),
		Secondary = Color3.fromRGB(0, 0, 68),
		Text = Color3.fromRGB(255, 255, 255),
		TextStroke = Color3.fromRGB(0, 0, 0),
		UIStroke = Color3.fromRGB(255, 255, 255),
	},
} :: {[string]: Theme}

local THEME_TRANSITION_TIME = 0.25
function module.UpdateThemeInstance(v: Instance, theme: Theme?, noTransition: boolean?): ()
	-- Updates the theme for one instance
	-- Tag StyledUI means that a UI object will be updated to match the theme
	-- Attribute Style is the style to use for the main element(s) of an object (e.g, background colour for a frame, image colour for an image)
	
	local SettingsManager = require(script.Parent.SettingsManager)
	local UIAnimation = require(script.Parent.UIAnimation)
	local tweenInfo = TweenInfo.new(THEME_TRANSITION_TIME, Enum.EasingStyle.Linear, Enum.EasingDirection.In)
	theme = theme or module.Themes[SettingsManager.GetSetting("UI Theme") :: string]
	assert(theme)
	
	local inverse = v:GetAttribute("Inverse")
	local keepText = v:GetAttribute("KeepText")
	local updateImage = v:GetAttribute("UpdateImage")
	
	local style = v:GetAttribute("Style")
	
	if v.ClassName == "UIStroke" then
		UIAnimation.Animate(v, tweenInfo, {Color = if not inverse then theme["UIStroke"] else theme[style or "Text"]}, noTransition)
	elseif (v.ClassName == "TextButton") or (v.ClassName == "TextLabel") then
		if not keepText then
			UIAnimation.Animate(v, tweenInfo, {
				TextColor3 = (not inverse) and theme.Text or theme[style or "Primary"],
				TextStrokeColor3 = (not inverse) and theme.TextStroke or theme[style or "Text"]
			}, noTransition)
		end
	elseif (v.ClassName == "ImageButton") or (v.ClassName == "ImageLabel") then
		if updateImage then
			UIAnimation.Animate(v, tweenInfo, {ImageColor3 = (not inverse) and theme[style or "Text"] or theme[style or "Primary"]}, noTransition)
		end
	elseif v.ClassName == "ChatWindowConfiguration" then
		UIAnimation.Animate(v, tweenInfo, {
			BackgroundColor3 = if not inverse then theme[style or "Primary"] else theme.Text,
			TextColor3 = if not inverse then theme.Text or theme.UIStroke else theme[style or "Primary"]
		})
	elseif v.ClassName == "ChatInputBarConfiguration" then
		UIAnimation.Animate(v, tweenInfo, {
			BackgroundColor3 = if not inverse then theme[style or "Primary"] else theme.Text,
			TextColor3 = if not inverse then theme.Text or theme.UIStroke else theme[style or "Primary"]
		})
	end
	
	if v.ClassName ~= "UIStroke" and v.ClassName ~= "ChatInputBarConfiguration" and v.ClassName ~= "ChatWindowConfiguration" then
		UIAnimation.Animate(v, tweenInfo, {
			BackgroundColor3 = (not inverse) and theme[style or "Primary"] or theme.Text,
			BorderColor3 = (not inverse) and theme.UIStroke or theme[style or "Primary"]
		}, noTransition)
	end
	
	return
end

function module.UpdateTheme(theme: string | Theme): ()
	if typeof(theme) == "string" then
		theme = module.Themes[theme]
	end
	assert(typeof(theme) == "table")
	for _, v in CollectionService:GetTagged("StyledUI") do
		module.UpdateThemeInstance(v, theme)
	end
end

CollectionService:GetInstanceAddedSignal("StyledUI"):Connect(function(instance)
	module.UpdateThemeInstance(instance)
end)

return module