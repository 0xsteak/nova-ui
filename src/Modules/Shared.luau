type BaseLayout_Impl = {
    __index: BaseLayout_Impl,
    new: () -> BaseLayout,
    SetAdornee: (self: BaseLayout, adornee: GuiObject?) -> ()
}

type BaseLayout_self = {
    Class: "Layout",
    LayoutType: string,
    Adornee: GuiObject?
}

export type BaseLayout = typeof(setmetatable({} :: BaseLayout_Impl, {} :: BaseLayout_self))

return nil