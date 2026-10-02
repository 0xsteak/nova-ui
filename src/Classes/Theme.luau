local HttpService = game:GetService('HttpService')

export type ColorToken = keyof<ColorTokens>

export type ColorTokens = {
	Background: Color3,
	Foreground: Color3,
	PrimaryText: Color3,
	SecondaryText: Color3,
	Accent: Color3,
	Surface: Color3,
}

type ThemeProps = {
	Id: string,
	Name: string,
	Author: string,
	ColorTokens: ColorTokens,
}

local Theme = {}
Theme.__index = Theme

Theme.ClassName = 'NovaUI.Theme'

export type Theme = typeof(setmetatable({} :: ThemeProps, Theme))

function Theme.__tostring(self: Theme)
	return Theme.ClassName
end

function Theme.new(name: string, author: string, id: string?, colorTokens: ColorTokens): Theme
	local self: Theme = setmetatable({}, Theme)

	self.Id = id or HttpService:GenerateGUID(false)
	self.Name = name
	self.Author = author
	self.ColorTokens = colorTokens

	return self
end

function Theme.GetColorToken(self: Theme, token: ColorToken): Color3?
	return self.ColorTokens[token]
end

function Theme.ToJSON(self: Theme): string
	local object = {}

	object.Id = self.Id
	object.Name = self.Name
	object.Author = self.Author
	object.ColorTokens = {}

	for name: ColorToken, color: Color3 in self.ColorTokens do
		object[name] = color:ToHex()
	end

	return HttpService:JSONEncode(object)
end

return Theme
