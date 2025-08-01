local Theme = require("@self/../../Classes/Theme")
local TableUtils = require("@self/../../Utils/TableUtils")
local Signal = require("@self/../Signal")
local BuiltInThemes = require("./Themes") :: {Theme.Theme}

-- -- -- -- --

export type Registry = {
    Themes: {Theme.Theme},
    DefaultSettings: SettingsType,
    Settings: SettingsType,
    -- -- --
    SettingChanged: Signal.Signal<RegistrySetting, any>,
    -- -- --
    RegisterTheme: (theme: Theme.Theme) -> (),
    GetThemeId: (name: string) -> number?,
    UpdateSettings: (settings: SettingsType) -> (),
    ResetSettings: () -> ()
}

export type SettingsType = {
    ScreenGui: ScreenGui,
    Font: Font,
    CurrentThemeId: number,
    AnimationsEnabled: boolean
}
export type RegistrySetting = "ScreenGui" | "Font" | "CurrentThemeId" | "AnimationsEnabled"

-- -- -- -- --

local Registry = {} :: Registry

Registry.Themes = BuiltInThemes

Registry.DefaultSettings = {
    Font = Font.new("rbxassetid://12187365364"),
    CurrentThemeId = 1,
    AnimationsEnabled = true
}

local Settings = TableUtils.DeepClone(Registry.DefaultSettings)

Registry.SettingChanged = Signal.new()

function Registry.RegisterTheme(theme: Theme.Theme): number
    table.insert(Registry.Themes, theme)

    return #Registry.Themes
end

function Registry.GetThemeId(themeName: string): number?
    for i = 1, #Registry.Themes do
        if Registry.Themes[i].Name == themeName then
            return i
        end
    end

    return nil
end

function Registry.UpdateSettings(settings: SettingsType)
    TableUtils.MergeInto(Settings, settings)
end

function Registry.ResetSettings()
    Settings = TableUtils.DeepClone(Registry.DefaultSettings)
end

Registry.Settings = setmetatable({}, {
    __index = Settings,
    __newindex = function(self, setting: RegistrySetting, value)
        Settings[setting] = value
        Registry.SettingChanged:Fire(setting, value)
    end
})

return Registry