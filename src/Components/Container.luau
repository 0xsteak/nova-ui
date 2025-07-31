local Shared = require("../Modules/Shared")

-- -- -- -- --

type ContainerImpl = {
    __index: ContainerImpl,
    new: () -> Container,
    fromObject: (object: GuiObject) -> Container,
    SetLayout: (self: Container, layout: Shared.BaseLayout) -> (),
    SetParent: (self: Container, parent: Instance) -> ()
}

type self = {
    Class: "Container",
    Instance: GuiObject,
    Layout: Shared.BaseLayout?
}

export type Container = typeof(setmetatable({} :: self, {} :: ContainerImpl))

-- -- -- -- --

local Container = {} :: ContainerImpl
Container.__index = Container

function Container.new(): Container
    local self = setmetatable({}, Container)

    self.Instance = Instance.new("Frame")

    return self
end

function Container.fromObject(object: GuiObject): Container
    local self = setmetatable({}, Container)

    self.Instance = object

    return self
end

function Container.SetLayout(self: Container, layout: Shared.BaseLayout)
    if self.Layout then
        self.Layout:SetAdornee(nil)
    end

    layout:SetAdornee(self.Instance)
    self.Layout = layout
end

function Container.SetParent(self: Container, parent: Instance)
    self.Instance.Parent = parent
end

return Container