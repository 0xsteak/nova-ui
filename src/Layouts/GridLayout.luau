type GridLayoutImpl = {
    __index: GridLayoutImpl,
    new: () -> GridLayout,
    SetAdornee: (self: GridLayout, adornee: GuiObject?) -> (),
    Destroy: (self: GridLayout) -> ()
}

type self = {
    Class: "Layout",
    LayoutType: "Grid",
    Adornee: GuiObject?,
    Instance: UIGridLayout
}

export type GridLayout = typeof(setmetatable({} :: self, {} :: GridLayoutImpl))

-- -- -- -- --

local GridLayout = {} :: GridLayoutImpl
GridLayout.__index = GridLayout

function GridLayout.new(): GridLayout
    local self = setmetatable({}, GridLayout) :: GridLayout

    self.Instance = Instance.new("UIGridLayout")

    return self
end

function GridLayout.SetAdornee(self: GridLayout, adornee: GuiObject?)
    self.Adornee = adornee
    self.Instance.Parent = adornee
end

function GridLayout.Destroy(self: GridLayout)
    self.Instance:Destroy()

    setmetatable(self :: any, nil)
    table.clear(self :: any)
end

return GridLayout