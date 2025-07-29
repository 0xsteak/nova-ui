type BlueprintImpl = {
    __index: BlueprintImpl,
    new: (blueprintData: BlueprintData) -> Blueprint,
    Build: (self: Blueprint) -> Instance,
    Destroy: (self: Blueprint) -> ()
}

-- ye, ik its kinda dumb
export type BlueprintData = {
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
    [number]: BlueprintData
}

type self = {
    Class: "Blueprint",
    Instance: Instance,
}

export type Blueprint = typeof(setmetatable({} :: self, {} :: BlueprintImpl))

-- -- -- -- --

local Blueprint = {} :: BlueprintImpl
Blueprint.__index = Blueprint

local function buildFromData(blueprintData: BlueprintData): Instance
    local instance = Instance.new(blueprintData.Class)

    for property, value in blueprintData do
        if property == "Class" then continue end

        if typeof(property) == "number" then
            if typeof(value) == "table" then
                buildFromData(value).Parent = instance
            elseif typeof(value) == "Instance" then
                value.Parent = instance
            end
            continue
        end

        instance[property] = value
    end

    return instance
end

function Blueprint.new(blueprintData: BlueprintData): Blueprint
    local self = setmetatable({}, Blueprint) :: Blueprint
    
    self.Class = "Blueprint"
    self.Instance = buildFromData(blueprintData)

    return self
end

function Blueprint.Build(self: Blueprint): Instance
    return self.Instance:Clone()
end

function Blueprint.Destroy(self: Blueprint)
    self.Instance:Destroy()

    setmetatable(self :: any, nil)
    table.clear(self :: any)
end

return Blueprint