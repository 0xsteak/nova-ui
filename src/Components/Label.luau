local TableUtils = require("../Utils/TableUtils")
local Registry = require("../Modules/Registry")
local Blueprint = require("../Modules/Blueprint")
local ThemeService = require("../Modules/ThemeService")

-- -- -- -- --

type LabelImpl = {
    __index: LabelImpl,
    new: (options: LabelOptions) -> Label,
    SetText: (self: Label, text: string) -> (),
    SetXAlignment: (self: Label, alignment: Enum.TextXAlignment) -> (),
    SetYAlignment: (self: Label, alignment: Enum.TextYAlignment) -> (),
    SetSize: (self: Label, size: UDim2) -> (),
    SetTextSize: (self: Label, size: number) -> (),
    SetParent: (self: Label, parent: Instance) -> (),
    Destroy: (self: Label) -> ()
}

type self = {
    Class: "Label",
    Instance: TextLabel,
    AutoHeight: boolean,
    Params: GetTextBoundsParams
}

export type Label = typeof(setmetatable({} :: self, {} :: LabelImpl))

type LabelOptions = {
    Text: string?,
    TextXAlignment: Enum.TextXAlignment?,
    TextYAlignment: Enum.TextYAlignment?,
    AutoHeight: boolean?,
    Size: UDim2?,
    TextSize: number
}

-- -- -- -- --

local Label = {} :: LabelImpl
Label.__index = Label

local TextService = game:GetService("TextService")

local BaseBlueprint = Blueprint.new({
    Class = "TextLabel",
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    FontFace = Registry.Settings.Font,
    TextWrapped = true
})

local function updateHeight(self: Label)
    if not self.AutoHeight then return end

    local instance = self.Instance
    local params = self.Params
    local width = instance.AbsoluteSize.X
    local sizeX = instance.Size.X

    params.Text = instance.Text
    params.Width = width

    local height = TextService:GetTextBoundsAsync(params).Y

    instance.Size = UDim2.new(sizeX.Scale, sizeX.Offset, 0, height)
end

local DefaultOptions = {
    Text = "Label",
    TextXAlignment = Enum.TextXAlignment.Center,
    TextYAlignment = Enum.TextYAlignment.Center,
    AutoHeight = true,
    Size = UDim2.new(0, 100, 0, 100),
    TextSize = 14
} :: LabelOptions

function Label.new(options: LabelOptions): Label
    options = TableUtils.Merge(DefaultOptions, options)

    local self = setmetatable({}, Label) :: Label

    local instance = BaseBlueprint:Build() :: TextLabel

    self.Class = "Label"
    self.Instance = instance
    self.AutoHeight = options.AutoHeight

    ThemeService.Link(instance, "PrimaryText", {"TextColor3"})
    ThemeService.Update()

    local params = Instance.new("GetTextBoundsParams")
    params.Font = instance.FontFace
    params.Size = 1/0
    params.Width = instance.AbsoluteSize.X

    self.Params = params

    local lastWidth = instance.AbsoluteSize.X
    instance:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
        local width = instance.AbsoluteSize.X
        if width ~= lastWidth then
            updateHeight(self)
            lastWidth = width
        end
    end)
    instance:GetPropertyChangedSignal("Text"):Connect(function()
        updateHeight(self)
    end)

    self:SetText(options.Text)
    self:SetXAlignment(options.TextXAlignment)
    self:SetYAlignment(options.TextYAlignment)
    self:SetSize(options.Size)
    self:SetTextSize(options.TextSize)

    return self
end

function Label.SetText(self: Label, text: string)
    self.Instance.Text = text
end

function Label.SetXAlignment(self: Label, alignment: Enum.TextXAlignment)
    self.Instance.TextXAlignment = alignment
end

function Label.SetYAlignment(self: Label, alignment: Enum.TextYAlignment)
    self.Instance.TextYAlignment = alignment
end

function Label.SetSize(self: Label, size: UDim2)
    self.Instance.Size = size
end

function Label.SetTextSize(self: Label, size: number)
    self.Instance.TextSize = size
end

function Label.SetParent(self: Label, parent: Instance)
    self.Instance.Parent = parent
end

function Label.Destroy(self: Label)
    self.Instance:Destroy()
    self.Params:Destroy()

    setmetatable(self :: any, nil)
    table.clear(self :: any)
end

return Label