type ListLayoutImpl = {
    __index: ListLayoutImpl,
    new: () -> ListLayout,
    SetAdornee: (self: ListLayout, adornee: GuiObject?) -> ()
}

type self = {
    Class: "Layout",
    LayoutType: "List",
    Adornee: GuiObject?,
    Instance: UIListLayout
}

export type ListLayout = typeof(setmetatable({} :: self, {} :: ListLayoutImpl))

-- -- -- -- --

local ListLayout = {} :: ListLayoutImpl
ListLayout.__index = ListLayout

function ListLayout.new(): ListLayout
    local self = setmetatable({}, ListLayout) :: ListLayout

    self.Instance = Instance.new("UIListLayout")

    return self
end

function ListLayout.SetAdornee(self: ListLayout, adornee: GuiObject?)
    self.Adornee = adornee
    self.Instance.Parent = adornee
end

return ListLayout