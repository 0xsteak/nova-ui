local Blueprint = require("./Blueprint")

-- -- -- -- --

type DropShadowType = "Window"

type DropShadowImpl = {
    __index: DropShadowImpl,
    new: (dropShadowType: DropShadowType) -> DropShadow,
    SetAdornee: (self: DropShadow, adornee: GuiObject) -> (),
    Destroy: (self: DropShadow) -> ()
}

type self = {
    Class: "DropShadow",
    Type: DropShadowType,
    Instance: ImageLabel,
    Adornee: GuiObject?,
    AdorneeConnections: {RBXScriptConnection}
}

export type DropShadow = typeof(setmetatable({} :: self, {} :: DropShadowImpl))

-- -- -- -- --

local DropShadow = {} :: DropShadowImpl
DropShadow.__index = DropShadow

local types: {[DropShadowType]: {image: string, slice: Rect, sizeOffset: number, minSlice: number}} = {
    Window = {
        image = "rbxassetid://125697777092780",
        slice = Rect.new(100, 100, 924, 924),
        sizeOffset = 120,
        minSlice = 70
    }
}

local function update(self: DropShadow)
    local instance = self.Instance
    local adornee = self.Adornee

    instance.Visible = adornee.Visible
    instance.Parent = adornee.Parent

    if adornee:IsA("CanvasGroup") then
        instance.ImageTransparency = adornee.GroupTransparency
    end

    local adorneePos = adornee.AbsolutePosition
    local adorneeSize = adornee.AbsoluteSize
    local typeInfo = types[self.Type :: DropShadowType]
    local sizeOffset = typeInfo.sizeOffset
    local slice = typeInfo.slice
    local minSlice = typeInfo.minSlice
    local sliceOffsetX = slice.Min.X
    local sliceOffsetY = slice.Min.Y

    if adorneeSize.X < sliceOffsetX then
        local oldSlice = instance.SliceCenter
        instance.SliceCenter = Rect.new(math.clamp(adorneeSize.X, minSlice, 1/0), oldSlice.Min.Y, 1024 - math.clamp(adorneeSize.X, minSlice, 1/0), oldSlice.Max.Y)
    end
    if adorneeSize.Y < sliceOffsetY then
        local oldSlice = instance.SliceCenter
        instance.SliceCenter = Rect.new(oldSlice.Min.X, math.clamp(adorneeSize.Y, minSlice, 1/0), oldSlice.Max.X, 1024 - math.clamp(adorneeSize.Y, minSlice, 1/0))
    end
    if not (adorneeSize.X < sliceOffsetX or adorneeSize.Y < sliceOffsetY) then
        instance.SliceCenter = slice
    end

    instance.Position = UDim2.fromOffset(adorneePos.X - sizeOffset / 2, adorneePos.Y - sizeOffset / 2)
    instance.Size = UDim2.fromOffset(adorneeSize.X + sizeOffset, adorneeSize.Y + sizeOffset)
end

local function disconnectAdornee(self: DropShadow)
    local connections = self.AdorneeConnections
    for i = 1, #connections do
        connections[i]:Disconnect()
    end
end

local BaseBlueprint = Blueprint.new({
    Class = "ImageLabel",
    BackgroundTransparency = 1,
    ZIndex = -1
})

function DropShadow.new(dropShadowType: DropShadowType): DropShadow
    local self = setmetatable({}, DropShadow) :: DropShadow

    local typeInfo = types[dropShadowType]
    local image = typeInfo.image
    local slice = typeInfo.slice

    local instance = BaseBlueprint:Build() :: ImageLabel

    self.Class = "DropShadow"
    self.Type = dropShadowType
    self.Instance = instance
    self.AdorneeConnections = {}
    
    instance.Image = image
    instance.ScaleType = Enum.ScaleType.Slice
    instance.SliceCenter = slice

    return self
end

function DropShadow.SetAdornee(self: DropShadow, adornee: GuiObject)
    disconnectAdornee(self)

    local function updateThis()
        update(self)
    end

    self.Adornee = adornee

    self.AdorneeConnections[1] = game:GetService("RunService").RenderStepped:Connect(updateThis)

    updateThis()
end

function DropShadow.Destroy(self: DropShadow)
    disconnectAdornee(self)
    self.Instance:Destroy()

    setmetatable(self :: any, nil)
    table.clear(self :: any)
end

return DropShadow