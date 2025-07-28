local Theme = require("../Classes/Theme")
local TableUtils = require("../Utils/TableUtils")
local Registry = require("./Registry")
local Signal = require("./Signal")
local Tweener = require("./Tweener")

-- -- -- -- --

export type ThemeService = {
    Link: (object: GuiObject, themeProperty: ThemeColorProperty, properties: { ObjProperty }) -> (),
    Unlink: (object: GuiObject, themeProperty: ThemeColorProperty?) -> (),
    Update: () -> (),
    GetColor: (property: ThemeColorProperty) -> Color3,
    ThemeChanged: Signal.Signal<ThemeObjectColors>
}

type ThemeColorProperty = Theme.ThemeColor
type ThemeObjectColors = Theme.ThemeColors
type Theme = Theme.Theme

type ObjProperty = "BackgroundColor3" | "TextColor3" | "ImageColor3"

type Links = {
    [ThemeColorProperty]: {
        [GuiObject]: number
    }
}

-- -- -- -- --

local ThemeService = {} :: ThemeService

local ObjProperties: {ObjProperty} = {"BackgroundColor3", "TextColor3", "ImageColor3"}
local Links: Links = {}
local ThemeId = Registry.Settings.CurrentThemeId
local CurrentTheme: ThemeObjectColors = TableUtils.DeepClone(Registry.Themes[ThemeId].Colors)

local function getObjProps(propertyNum: number): {ObjProperty}
    local props: { ObjProperty } = {}

    for index, property in ObjProperties do
        local bit = 2^(index - 1)
        if bit32.band(propertyNum, bit) == bit then
            table.insert(props, property) 
        end
    end

    return props
end

function ThemeService.Link(object: GuiObject, themeProperty: ThemeColorProperty, properties: {ObjProperty})
    local propertyNum = 0

    if not Links[themeProperty] then
        Links[themeProperty] = {}
    end

    for index, property in ObjProperties do
        if table.find(properties, property) then
            propertyNum = bit32.bor(propertyNum, 2^(index - 1))
        end
    end
    
    Links[themeProperty][object] = propertyNum
end

function ThemeService.Unlink(object: GuiObject, themeProperty: ThemeColorProperty?)
    if themeProperty and not Links[themeProperty] then
        Links[themeProperty] = {}
        return
    end

    if themeProperty then
        Links[themeProperty][object] = nil
        return
    end

    for property, objects in Links do
        objects[object] = nil
    end
end

function ThemeService.Update()
    assert(CurrentTheme, "ThemeService.Update: Theme is not set.")

    for themeProperty, objects in Links do
        for object, propertyNum in pairs(objects) do
            local props = getObjProps(propertyNum)
            for _, prop: ObjProperty in props do
                object[prop] = CurrentTheme[themeProperty]
            end
        end
    end
end

function ThemeService.GetColor(property: ThemeColorProperty): Color3
    return CurrentTheme[property]
end

ThemeService.ThemeChanged = Signal.new()

Registry.SettingChanged:Connect(function(setting, value: number)
    if setting == "CurrentThemeId" then
        TableUtils.MergeInto(CurrentTheme, Registry.Themes[value].Colors)
        ThemeService.ThemeChanged:Fire(CurrentTheme)
        Tweener.StopColorTweens()
        ThemeService.Update()
    end
end)

return ThemeService