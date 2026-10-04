type BaseLayout_Impl = {
	__index: BaseLayout_Impl,
	new: (target: GuiObject?) -> BaseLayout,
	SetTarget: (self: BaseLayout, target: GuiObject?) -> (),
	Destroy: (self: BaseLayout) -> (),
}

type BaseLayout_self = {
	Target: GuiObject?,
	TargetConnection: RBXScriptConnection?,
}

export type BaseLayout = typeof(setmetatable({} :: BaseLayout_Impl, {} :: BaseLayout_self))

return nil
