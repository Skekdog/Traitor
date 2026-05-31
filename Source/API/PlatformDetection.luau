--!nolint DeprecatedApi

-- This script is taken from https://devforum.roblox.com/t/the-most-accurate-operating-system-detector/3772157/21.
-- It has been shrunk down to the specific needs of Traitor.

--[[
    OSDetector
    ============================================================
    A reusable module for detecting the operating system / platform
    of a Roblox client.

    DETECTION ORDER
    ---------------
    Primary:   Version-string prefix  (most reliable)
    Secondary: GuiService / VRService flags
    Tertiary:  Unicode character width heuristics
    Fallback:  KeyCode image strings, touch presence, misc flags
    Final:     Enum.Platform.None  (unknown)
--]]

local OSDetector = {}

type DeprecatedGuiService = GuiService & { IsWindows: boolean }

-- Unicode codepoints used in detection
local CODEPOINT = {
	APPLE       = 0xF8FF,   -- Apple logo on Apple platforms
	REPLACEMENT = 0xFFFD,   -- U+FFFD replacement character
	INVALID     = 0xFFFF,   -- Always-invalid sentinel
}

-- Version-string patterns (see article)
local VERSION_PATTERN = {
	DESKTOP = "^0%.",   -- e.g. 0.major.revision.all
	CONSOLE = "^1%.",   -- e.g. 1.major.revision.?
	MOBILE  = "^2%.",   -- e.g. 2.major.?
}

local GuiService        = game:GetService("GuiService")
local UserInputService  = game:GetService("UserInputService")
local VRService         = game:GetService("VRService")
local TextService       = game:GetService("TextService")

------------------------------------------------------------
-- HELPERS
------------------------------------------------------------

--- Returns the rendered pixel size of a single Unicode character.
local function getCharSize(codepoint: number): Vector2
	return TextService:GetTextSize(
		utf8.char(codepoint), 16, Enum.Font.SourceSans, Vector2.new(1000, 1000)
	)
end

local _invalidSize = getCharSize(CODEPOINT.INVALID)

--- True when the codepoint renders to a different size than the
--- always-invalid sentinel (meaning the glyph actually exists).
local function glyphExists(codepoint: number): boolean
	return getCharSize(codepoint) ~= _invalidSize
end

--- True when the Apple logo glyph (U+F8FF) is present in the font,
--- which is the case on iOS and macOS (not macOS Roblox client as
--- noted in the article, so this is mainly used for iOS).
local function hasAppleGlyph(): boolean
	return glyphExists(CODEPOINT.APPLE)
end

--- Returns the lowercase image-path string Roblox associates with a
--- given KeyCode (used to differentiate Xbox vs PlayStation controllers).
local function keyImage(keyCode: Enum.KeyCode): string
	return UserInputService:GetImageForKeyCode(keyCode):lower()
end

--- Splits the Roblox version() string to identify client type.
local function clientFlags()
	local v = version()
	return {
		raw        = v,
		isDesktop  = v:find(VERSION_PATTERN.DESKTOP) ~= nil,
		isConsole  = GuiService:IsTenFootInterface() or v:find(VERSION_PATTERN.CONSOLE) ~= nil,
		isMobile   = v:find(VERSION_PATTERN.MOBILE)  ~= nil,
		isEmpty    = v == "",   -- Sober used to return "" – kept as legacy note
	}
end

------------------------------------------------------------
-- DETECTION STAGES
-- Each stage returns Enum.Platform or nil to continue.
------------------------------------------------------------

--- Stage 1: Console detection (Xbox / PlayStation)
local function detectConsole(ver): Enum.Platform?
	if not ver.isConsole then return nil end

	local img = keyImage(Enum.KeyCode.ButtonSelect)

	-- Primary: keycode image string
	if img:find("xbox") then    return Enum.Platform.XBoxOne end
	if img:find("ps5")  then    return Enum.Platform.PS5     end
	if img:find("ps4")  then    return Enum.Platform.PS4     end

	-- Secondary fallback: GuiService.IsWindows reliably flags Xbox
	if (GuiService :: DeprecatedGuiService).IsWindows then return Enum.Platform.XBoxOne end

	-- Tertiary: L2 keycode image (from article – ButtonLT = Xbox, ButtonL2 = PS)
	local l2img = keyImage(Enum.KeyCode.ButtonL2)
	if l2img:find("xbox") then  return Enum.Platform.XBoxOne end
	if l2img:find("ps")   then  return Enum.Platform.PS4     end  -- generic PS fallback

	return nil  -- Unknown console
end

--- Stage 2: Mobile detection (iOS / Android / Sober / UWP / Meta)
local function detectMobile(ver): Enum.Platform?
	if not ver.isMobile then
		return nil
	end

	-- UWP (Microsoft Store) reports as mobile but runs on Windows
	if (GuiService :: DeprecatedGuiService).IsWindows then
		return Enum.Platform.UWP
	end

	-- Meta Quest: mobile client with VR enabled
	if UserInputService.VREnabled and VRService.VREnabled then
		return Enum.Platform.MetaOS
	end

	-- iOS: Apple private-use glyph present
	if hasAppleGlyph() then
		return Enum.Platform.IOS
	end

	-- Sober (Linux): Android client but TouchEnabled is suppressed.
	-- The Android engine hardcodes TouchEnabled=true; Sober patches
	-- this out, making it the only non-Quest Android build without touch.
	if not UserInputService.TouchEnabled then
		return Enum.Platform.Linux
	end

	-- Default mobile → Android
	return Enum.Platform.Android
end

--- Stage 3: Desktop detection (Windows / macOS)
local function detectDesktop(ver): Enum.Platform?
	if not ver.isDesktop then
		return nil
	end

	if (GuiService :: DeprecatedGuiService).IsWindows then
		return Enum.Platform.Windows
	end

	-- macOS: only remaining desktop client.
	-- NOTE: hasAppleGlyph() is intentionally NOT used here because the
	-- macOS Roblox client does not appear to render U+F8FF (see article).
	return Enum.Platform.OSX
end

--- Stage 4: Heuristic fallbacks when version() is empty / unrecognised.
--- Covers edge cases like old Sober builds that returned "".
local function detectFallback(): Enum.Platform?
	-- VR implies Meta Quest (most likely mobile+VR combo)
	if UserInputService.VREnabled and VRService.VREnabled then
		return Enum.Platform.MetaOS
	end

	-- Windows flag is reliable regardless of client type
	if (GuiService :: DeprecatedGuiService).IsWindows then
		return Enum.Platform.Windows
	end

	-- Ten-foot UI almost certainly means console
	if GuiService:IsTenFootInterface() then
		local img = keyImage(Enum.KeyCode.ButtonSelect)

		if img:find("xbox") then
			return Enum.Platform.XBoxOne
		elseif img:find("ps5") then
			return Enum.Platform.PS5
		elseif img:find("ps4") then
			return Enum.Platform.PS4
		end

		return Enum.Platform.XBoxOne  -- safest console default
	end

	-- Apple glyph → iOS (most common Apple mobile platform on Roblox)
	if hasAppleGlyph() then
		return Enum.Platform.IOS
	end

	-- No touch on an apparent mobile session → likely Sober
	if not UserInputService.TouchEnabled then
		return Enum.Platform.Linux
	end

	return nil
end

local function runDetection(): Enum.Platform
	local ver = clientFlags()

	local platform =
		detectConsole(ver)  or
		detectMobile(ver)   or
		detectDesktop(ver)  or
		detectFallback()    or
		Enum.Platform.None

	return platform
end

function OSDetector.Detect(): Enum.Platform
	return runDetection()
end

return table.freeze(OSDetector)