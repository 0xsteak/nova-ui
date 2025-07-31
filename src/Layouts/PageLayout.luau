type PageLayoutImpl = {
    __index: PageLayoutImpl,
    new: () -> PageLayout,
    SetAdornee: (self: PageLayout, adornee: GuiObject?) -> (),
    JumpTo: (self: PageLayout, page: Instance) -> (),
    JumpToIndex: (self: PageLayout, index: number) -> (),
    Next: () -> (),
    Previous: () -> ()
}

type self = {
    Class: "Layout",
    LayoutType: "Page",
    Adornee: GuiObject?,
    Instance: UIPageLayout
}

export type PageLayout = typeof(setmetatable({} :: self, {} :: PageLayoutImpl))

-- -- -- -- --

local PageLayout = {} :: PageLayoutImpl
PageLayout.__index = PageLayout

function PageLayout.new(): PageLayout
    local self = setmetatable({}, PageLayout) :: PageLayout

    self.Instance = Instance.new("UIPageLayout")

    return self
end

function PageLayout.SetAdornee(self: PageLayout, adornee: GuiObject?)
    self.Adornee = adornee
    self.Instance.Parent = adornee
end

function PageLayout.JumpTo(self: PageLayout, page: Instance)
    self.Instance:JumpTo(page)
end

function PageLayout.JumpToIndex(self: PageLayout, index: number)
    self.Instance:JumpToIndex(index)
end

function PageLayout.Next(self: PageLayout)
    self.Instance:Next()
end

function PageLayout.Previous(self: PageLayout)
    self.Instance:Previous()
end

return PageLayout