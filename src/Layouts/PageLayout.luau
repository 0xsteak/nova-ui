type PageLayoutProps = {
	Adornee: GuiObject?,
	Instance: UIPageLayout,
	AdorneeConnection: RBXScriptConnection?,
}

local PageLayout = {}
PageLayout.__index = PageLayout

PageLayout.ClassName = 'NovaUI.PageLayout'

export type PageLayout = typeof(setmetatable({} :: PageLayoutProps, PageLayout))

function PageLayout.__tostring(self: PageLayout)
	return PageLayout.ClassName
end

function PageLayout.new(adornee: GuiObject?): PageLayout
	local self: PageLayout = setmetatable({}, PageLayout)

	self.Instance = Instance.new('UIPageLayout')

	self:SetAdornee(adornee)

	return self
end

function PageLayout.SetAdornee(self: PageLayout, adornee: GuiObject?)
	if self.AdorneeConnection then
		self.AdorneeConnection:Disconnect()
	end

	self.Adornee = adornee
	self.Instance.Parent = adornee

	if adornee then
		self.AdorneeConnection = adornee.Destroying:Once(function()
			self:Destroy()
		end)
	end
end

function PageLayout.JumpTo(self: PageLayout, page: Instance)
	self.Instance:JumpTo(page)
end

function PageLayout.JumpToIndex(self: PageLayout, index: number)
	self.Instance:JumpToIndex(index)
end

function PageLayout.Next(self: PageLayout)
	self.Instance:Next()
end

function PageLayout.Previous(self: PageLayout)
	self.Instance:Previous()
end

function PageLayout.Destroy(self: PageLayout)
	self.Instance:Destroy()
	if self.AdorneeConnection then
		self.AdorneeConnection:Disconnect()
	end
end

return PageLayout
