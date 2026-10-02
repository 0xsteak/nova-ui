type ListLayoutProps = {
	Adornee: GuiObject?,
	Instance: UIListLayout,
	AdorneeConnection: RBXScriptConnection?,
}

local ListLayout = {}
ListLayout.__index = ListLayout

ListLayout.ClassName = 'NovaUI.ListLayout'

export type ListLayout = typeof(setmetatable({} :: ListLayoutProps, ListLayout))

function ListLayout.__tostring(self: ListLayout)
	return ListLayout.ClassName
end

function ListLayout.new(adornee: GuiObject?): ListLayout
	local self: ListLayout = setmetatable({}, ListLayout)

	self.Instance = Instance.new('UIListLayout')

	self:SetAdornee(adornee)

	return self
end

function ListLayout.SetAdornee(self: ListLayout, adornee: GuiObject?)
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

function ListLayout.Destroy(self: ListLayout)
	self.Instance:Destroy()
	if self.AdorneeConnection then
		self.AdorneeConnection:Disconnect()
	end
end

return ListLayout
