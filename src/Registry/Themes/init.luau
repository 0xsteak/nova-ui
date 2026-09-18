local Theme = require(script.Parent.Parent.Classes.Theme)

local Themes = {}

local ThemesRegistry: { [string]: Theme.Theme } = {}

function Themes.Register(theme: Theme.Theme)
	local id = theme.Id

	assert(not Themes.IsRegistered(id), 'Theme is already registered')

	ThemesRegistry[id] = theme
end

function Themes.IsRegistered(themeId: string): boolean
	return ThemesRegistry[themeId] and true or false
end

function Themes.GetTheme(themeId: string): Theme.Theme?
	return ThemesRegistry[themeId]
end

for _, theme in script:GetChildren() do
	if theme:IsA('ModuleScript') then
		Themes.Register(require(theme))
	end
end

return Themes
