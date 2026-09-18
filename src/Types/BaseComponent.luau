type BaseComponent_Impl = {
	__index: BaseComponent_Impl,
	new: () -> BaseComponent,
	SetParent: (self: BaseComponent, parent: Instance) -> (),
	Destroy: (self: BaseComponent) -> (),
}

type BaseComponent_self = {
	Class: string,
	Instance: GuiObject,
}

export type BaseComponent = typeof(setmetatable({} :: BaseComponent_self, {} :: BaseComponent_Impl))

return nil
