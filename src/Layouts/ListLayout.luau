type ListLayoutProps = {
	Target: GuiObject?,
	Base: UIListLayout,
	_targetConnection: RBXScriptConnection?,
}

local ListLayout = {}
ListLayout.__index = ListLayout

ListLayout.ClassName = 'NovaUI.ListLayout'

export type ListLayout = typeof(setmetatable({} :: ListLayoutProps, ListLayout))

function ListLayout.__tostring(self: ListLayout)
	return ListLayout.ClassName
end

function ListLayout.new(target: GuiObject?): ListLayout
	local self: ListLayout = setmetatable({}, ListLayout)

	self.Base = Instance.new('UIListLayout')

	self:SetTarget(target)

	return self
end

function ListLayout.SetTarget(self: ListLayout, target: GuiObject?)
	if self._targetConnection then
		self._targetConnection:Disconnect()
	end

	self.Target = target
	self.Base.Parent = target

	if target then
		self._targetConnection = target.Destroying:Once(function()
			self:Destroy()
		end)
	end
end

function ListLayout.Destroy(self: ListLayout)
	self.Base:Destroy()
	if self._targetConnection then
		self._targetConnection:Disconnect()
	end
end

return ListLayout
