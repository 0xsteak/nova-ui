export type BlueprintModule = {
    Build: (blueprintObj: Blueprint) -> Instance
}

export type Blueprint = {
    -- Instance
    Class: string,
    Name: string?,
    Parent: Instance?,
    -- GuiObject
    Active: boolean?,
    AnchorPoint: Vector2?,
    AutomaticSize: Enum.AutomaticSize?,
    BackgroundColor3: Color3?,
    BackgroundTransparency: number?,
    BorderColor3: Color3?,
    BorderMode: Enum.BorderMode?,
    BorderSizePixel: number?,
    ClipsDescendants: boolean?,
    Interactable: boolean?,
    LayoutOrder: number?,
    Position: UDim2?,
    Rotation: number?,
    Size: UDim2?,
    Visible: boolean?,
    ZIndex: number?,
    -- GuiButton
    AutoButtonColor: boolean?,
    Modal: boolean?,
    Style: Enum.ButtonStyle?,
    -- CanvasGroup
    GroupColor3: Color3?,
    GroupTransparency: number?,
    -- ImageLabel
    Image: string?,
    ImageColor3: Color3?,
    ImageContent: Content?,
    ImageRectOffset: Vector2?,
    ImageRectSize: Vector2?,
    ImageTransparency: number?,
    ResampleMode: Enum.ResamplerMode?,
    ScaleType: Enum.ScaleType?,
    SliceCenter: Rect?,
    SliceScale: number?,
    TileSize: UDim2?,
    -- ImageButton
    HoverImage: string?,
    PressedImage: string?,
    -- Path2D
    Closed: boolean?,
    Color3: boolean?,
    Thickness: number?,
    -- ScrollingFrame
    AutomaticCanvasSize: Enum.AutomaticSize?,
    BottomImage: string?,
    CanvasPosition: UDim2?,
    CanvasSize: UDim2?,
    ElasticBehavior: Enum.ElasticBehavior?,
    HorizontalScrollBarInset: Enum.ScrollBarInset?,
    MidImage: string?,
    ScrollBarImageColor3: Color3?,
    ScrollBarImageTransparency: number?,
    ScrollBarThickness: number?,
    ScrollingDirection: Enum.ScrollingDirection?,
    ScrollingEnabled: boolean?,
    TopImage: string?,
    VerticalScrollBarInset: Enum.ScrollBarInset?,
    VerticalScrollBarPosition: Enum.VerticalScrollBarPosition?,
    -- TextBox
    ClearTextOnFocus: boolean?,
    CursorPosition: number?,
    FontFace: Font?,
    LineHeight: number?,
    MaxVisibleGraphemes: number?,
    MultiLine: boolean?,
    PlaceholderColor3: Color3?,
    PlaceholderText: string?,
    RichText: boolean?,
    SelectionStart: number?,
    ShowNativeInput: boolean?,
    Text: string?,
    TextColor3: Color3?,
    TextDirection: Enum.TextDirection?,
    TextEditable: boolean?,
    TextScaled: boolean?,
    TextSize: number?,
    TextStrokeColor3: Color3?,
    TextStrokeTransparency: number?,
    TextTransparency: number?,
    TextTruncate: Enum.TextTruncate?,
    TextWrapped: boolean?,
    TextXAlignment: Enum.TextXAlignment?,
    TextYAlignment: Enum.TextYAlignment?,
    -- UICorner
    CornerRadius: UDim?,
    -- UIListLayout
    HorizontalFlex: Enum.UIFlexAlignment?,
    ItemLineAlignment: Enum.ItemLineAlignment?,
    Padding: UDim?,
    VerticalFlex: Enum.UIFlexAlignment?,
    Wraps: boolean?,
    AbsoluteContentSize: Vector2?,
    FillDirection: Enum.FillDirection?,
    HorizontalAlignment: Enum.HorizontalAlignment?,
    SortOrder: Enum.SortOrder?,
    VerticalAlignment: Enum.VerticalAlignment?,
    -- UIPadding
    PaddingBottom: UDim?,
    PaddingLeft: UDim?,
    PaddingRight: UDim?,
    PaddingTop: UDim?,
    -- UIScale
    Scale: number?,
    -- -- -- -- --
    [number]: Blueprint
}

-- -- -- -- --

local Blueprint = {} :: BlueprintModule

function Blueprint.Build(blueprintObj)
    local object = Instance.new(blueprintObj.Class)

    for property, value in blueprintObj do
        if property == "Class" then continue end

        if typeof(property) == "number" then
            if typeof(value) == "table" then
                Blueprint.Build(value).Parent = object
            elseif typeof(value) == "Instance" then
                value.Parent = object
            end
            continue
        end

        object[property] = value
    end

    return object
end

return Blueprint