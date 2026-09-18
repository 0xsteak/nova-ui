local Theme = require(script.Parent.Parent.Classes.Theme)
local Preferences = require(script.Parent.Parent.Registry.Preferences)
local Themes = require(script.Parent.Parent.Registry.Themes)
local TransitionService = require(script.Parent.TransitionService)

type bindings = {
	[Theme.ColorToken]: {
		[GuiObject]: { [objProp]: true },
	},
}

type objProp = 'BackgroundColor3' | 'TextColor3' | 'ImageColor3'

local ThemeService = {}

local bindings: bindings = {}
local currentTokens: Theme.ColorTokens = {}
local bindedObjects: { [GuiObject]: true } = {}

local dirtyTokens: { [Theme.ColorToken]: true } = {}

local function updateCurrentTokens(themeId: string?)
	local newTokens: Theme.ColorTokens = Themes.GetTheme(themeId or Preferences.GetCurrentThemeId()).ColorTokens

	for tokenName, tokenColor in newTokens do
		currentTokens[tokenName] = tokenColor
		dirtyTokens[tokenName] = true
	end
end

updateCurrentTokens('dark') -- to ensure that all tokens are assigned
updateCurrentTokens()

for token: Theme.ColorToken in currentTokens do
	bindings[token] = {}
end

function ThemeService.Bind(object: GuiObject, colorToken: Theme.ColorToken, property: objProp)
	local tokenBindings = bindings[colorToken]
	local objectBindings = tokenBindings[object]

	if not objectBindings then
		objectBindings = {}

		tokenBindings[object] = objectBindings
	end

	objectBindings[property] = true
	dirtyTokens[colorToken] = true

	if not bindedObjects[object] then
		object.Destroying:Once(function()
			ThemeService.UnbindAll(object)
		end)

		bindedObjects[object] = true
	end
end

function ThemeService.Unbind(object: GuiObject, colorToken: Theme.ColorToken, property: objProp)
	local tokenBindings = bindings[colorToken]

	if property and tokenBindings[object] then
		tokenBindings[object][property] = nil
	else
		bindings[colorToken][object] = nil
	end
end

function ThemeService.UnbindAll(object: GuiObject)
	for token in bindings do
		bindings[token][object] = nil
		bindedObjects[object] = nil
	end
end

function ThemeService.Update()
	for token in dirtyTokens do
		for object, objectBindings in bindings[token] do
			for property in objectBindings do
				object[property] = currentTokens[token]
			end
		end
		dirtyTokens[token] = nil
	end

	TransitionService.ApplyByTag('Theme', true)
end

function ThemeService.GetColorToken(token: Theme.ColorToken): Color3
	return currentTokens[token]
end

Preferences.CurrentThemeIdChanged:Connect(function(newThemeId: string)
	updateCurrentTokens(newThemeId)
	ThemeService.Update()
end)

return ThemeService
