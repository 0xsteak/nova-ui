type BaseLayout_Impl = {
    __index: BaseLayout_Impl,
    new: () -> BaseLayout,
    SetAdornee: (self: BaseLayout, adornee: GuiObject?) -> (),
    Destroy: (self: BaseLayout) -> ()
}

type BaseLayout_self = {
    Class: "Layout",
    LayoutType: string,
    Adornee: GuiObject?
}

export type BaseLayout = typeof(setmetatable({} :: BaseLayout_Impl, {} :: BaseLayout_self))

-- -- -- -- --

type BaseComponent_Impl = {
    __index: BaseComponent_Impl,
    new: () -> BaseComponent,
    SetParent: (self: BaseComponent, parent: Instance) -> (),
    Destroy: (self: BaseComponent) -> ()
}

type BaseComponent_self = {
    Class: string,
    Instance: GuiObject
}

export type BaseComponent = typeof(setmetatable({} :: BaseComponent_self, {} :: BaseLayout_Impl))

return nil