type ListLayoutProps = {
	ClassName: 'NovaUI.ListLayout',
	Adornee: GuiObject?,
	Instance: UIListLayout,
	AdorneeConnection: RBXScriptConnection,
}

local ListLayout = {}
ListLayout.__index = ListLayout

export type ListLayout = typeof(setmetatable({} :: ListLayoutProps, ListLayout))

function ListLayout.__tostring(self: ListLayout)
	return self.ClassName
end

function ListLayout.new(): ListLayout
	local self: ListLayout = setmetatable({}, ListLayout)

	self.ClassName = 'NovaUI.ListLayout'
	self.Instance = Instance.new('UIListLayout')

	return self
end

function ListLayout.SetAdornee(self: ListLayout, adornee: GuiObject?)
	if self.AdorneeConnection then
		self.AdorneeConnection:Disconnect()
	end

	self.Adornee = adornee
	self.Instance.Parent = adornee

	self.AdorneeConnection = adornee.Destroying:Once(function()
		self:Destroy()
	end)
end

function ListLayout.Destroy(self: ListLayout)
	self.Instance:Destroy()
end

return ListLayout
