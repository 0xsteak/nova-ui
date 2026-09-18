local Themes = require(script.Themes)
local Preferences = require(script.Preferences)

local Registry = {}

Registry.Themes = Themes
Registry.Preferences = Preferences

local RootScreenGui: ScreenGui

function Registry.SetRootScreenGui(screenGui: ScreenGui)
	RootScreenGui = screenGui
end

function Registry.GetRootScreenGui(): ScreenGui
	return assert(RootScreenGui, 'RootScreenGui is not set')
end

return Registry
