type BaseLayout_Impl = {
	__index: BaseLayout_Impl,
	new: (adornee: GuiObject?) -> BaseLayout,
	SetAdornee: (self: BaseLayout, adornee: GuiObject?) -> (),
	Destroy: (self: BaseLayout) -> (),
}

type BaseLayout_self = {
	Class: 'Layout',
	LayoutType: string,
	Adornee: GuiObject?,
	AdorneeConnection: RBXScriptConnection?,
}

export type BaseLayout = typeof(setmetatable({} :: BaseLayout_Impl, {} :: BaseLayout_self))

return nil
