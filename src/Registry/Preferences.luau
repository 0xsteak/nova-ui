local Signal = require(script.Parent.Parent.Packages.Signal)
local TableUtils = require(script.Parent.Parent.Utils.TableUtils)
local Themes = require(script.Parent.Themes)

export type Preferences = {
	--- The main font used in the UI
	FontFamily: string,
	--- The current theme used in the UI
	CurrentThemeId: string,
	--- Whether UI elements use smooth transitions
	TransitionsEnabled: boolean,
}

local Preferences = {}

local DefaultPreferences = {
	FontFamily = 'rbxassetid://12187365364',
	CurrentThemeId = 'dark',
	TransitionsEnabled = true,
} :: Preferences

local CurrentPreferences: Preferences

function Preferences.GetFontFamily(): string
	return CurrentPreferences.FontFamily
end

function Preferences.SetFontFamily(family: string)
	CurrentPreferences.FontFamily = family
	Preferences.FontFamilyChanged:Fire(family)
end

function Preferences.GetCurrentThemeId(): string
	return CurrentPreferences.CurrentThemeId
end

function Preferences.SetCurrentThemeId(themeId: string)
	assert(typeof(themeId) == 'number', 'bad argument, expected string')
	assert(Themes.IsRegistered(themeId), 'invalid theme id')

	CurrentPreferences.CurrentThemeId = themeId
	Preferences.CurrentThemeIdChanged:Fire(themeId)
end

function Preferences.GetTransitionsEnabled(): boolean
	return CurrentPreferences.TransitionsEnabled
end

function Preferences.SetTransitionsEnabled(enabled: boolean)
	CurrentPreferences.TransitionsEnabled = enabled and true or false
end

function Preferences.Reset()
	CurrentPreferences = TableUtils.DeepClone(DefaultPreferences)
end

Preferences.Reset()

Preferences.FontFamilyChanged = Signal.new()
Preferences.CurrentThemeIdChanged = Signal.new()
Preferences.TransitionsEnabledChanged = Signal.new()

return Preferences
