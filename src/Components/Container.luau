local BaseLayout = require(script.Parent.Parent.Types.BaseLayout)

type ContainerProps = {
	Base: GuiObject,
	Layout: BaseLayout.BaseLayout?,
}

local Container = {}
Container.__index = Container

Container.ClassName = 'NovaUI.Container'

export type Container = typeof(setmetatable({} :: ContainerProps, Container))

function Container.__tostring(self: Container)
	return Container.ClassName
end

function Container.new(): Container
	local self: Container = setmetatable({}, Container)

	self.Base = Instance.new('Frame')

	return self
end

function Container.fromGuiObject(object: GuiObject): Container
	local self = setmetatable({}, Container)

	self.Base = object

	return self
end

function Container.SetLayout(self: Container, layout: BaseLayout.BaseLayout)
	if self.Layout then
		self.Layout:SetTarget(nil)
	end

	layout:SetTarget(self.Base)
	self.Layout = layout
end

function Container.SetParent(self: Container, parent: Instance)
	self.Base.Parent = parent
end

function Container.Destroy(self: Container)
	if self.Layout then
		self.Layout:Destroy()
	end

	self.Base:Destroy()
end

return Container
