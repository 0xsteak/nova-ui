local TableUtils = require("../Utils/TableUtils")

-- -- -- -- --

type ThemeImpl = {
    __index: ThemeImpl,
    new: (name: string, author: string, highlightLocked: boolean, colors: ThemeColors) -> Theme,
    GetColor: (self: Theme, color: ThemeColor) -> Color3?,
    ToJSON: (self: Theme) -> string,
    Clone: (self: Theme) -> Theme,
    Destroy: (self: Theme) -> ()
}

export type ThemeColor = "Background" | "BackgroundDark" | "BackgroundLight" | "PrimaryText" | "SecondaryText"
| "Highlight" | "ScrollBarTrack" | "ScrollBarThumb"

export type ThemeColors = {
    [ThemeColor]: Color3
}

type self = {
    Class: "Theme",
    Name: string,
    Author: string,
    HighlightLocked: boolean,
    Colors: ThemeColors
}

export type Theme = typeof(setmetatable({} :: self, {} :: ThemeImpl))

-- -- -- -- --

local Theme = {} :: ThemeImpl
Theme.__index = Theme

local HttpService = game:GetService("HttpService")

function Theme.new(name: string, author: string, highlightLocked: boolean, colors: ThemeColors): Theme
    local self = setmetatable({}, Theme) :: Theme

    self.Class = "Theme"
    self.Name = name
    self.Author = author
    self.HighlightLocked = highlightLocked
    self.Colors = colors

    return self
end

function Theme.GetColor(self: Theme, color: ThemeColor): Color3?
    return self.Colors[color]
end

function Theme.ToJSON(self: Theme): string
    local object = {}

    object.Name = self.Name
    object.Author = self.Author
    object.HighlightLocked = self.HighlightLocked
    object.Colors = {}

    for name, color in self.Colors do
        object[name] = (color :: Color3):ToHex()
    end

    return HttpService:JSONEncode(object)
end

function Theme.Clone(self: Theme): Theme
    return Theme.new(self.Name, self.Author, self.HighlightLocked, TableUtils.DeepClone(self.Colors))
end

function Theme.Destroy(self: Theme)
    setmetatable(self :: any, nil)
    table.clear(self :: any)
end

return Theme