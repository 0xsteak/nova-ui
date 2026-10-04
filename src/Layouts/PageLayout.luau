type PageLayoutProps = {
	Target: GuiObject?,
	Base: UIPageLayout,
	_targetConnection: RBXScriptConnection?,
}

local PageLayout = {}
PageLayout.__index = PageLayout

PageLayout.ClassName = 'NovaUI.PageLayout'

export type PageLayout = typeof(setmetatable({} :: PageLayoutProps, PageLayout))

function PageLayout.__tostring(self: PageLayout)
	return PageLayout.ClassName
end

function PageLayout.new(target: GuiObject?): PageLayout
	local self: PageLayout = setmetatable({}, PageLayout)

	self.Base = Instance.new('UIPageLayout')

	self:SetTarget(target)

	return self
end

function PageLayout.SetTarget(self: PageLayout, target: GuiObject?)
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

function PageLayout.JumpTo(self: PageLayout, page: Instance)
	self.Base:JumpTo(page)
end

function PageLayout.JumpToIndex(self: PageLayout, index: number)
	self.Base:JumpToIndex(index)
end

function PageLayout.Next(self: PageLayout)
	self.Base:Next()
end

function PageLayout.Previous(self: PageLayout)
	self.Base:Previous()
end

function PageLayout.Destroy(self: PageLayout)
	self.Base:Destroy()
	if self._targetConnection then
		self._targetConnection:Disconnect()
	end
end

return PageLayout
