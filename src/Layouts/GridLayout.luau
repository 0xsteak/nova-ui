type GridLayoutProps = {
	ClassName: 'NovaUI.GridLayout',
	Adornee: GuiObject?,
	Instance: UIGridLayout,
	AdorneeConnection: RBXScriptConnection,
}

local GridLayout = {}
GridLayout.__index = GridLayout

export type GridLayout = typeof(setmetatable({} :: GridLayoutProps, GridLayout))

function GridLayout.__tostring(self: GridLayout)
	return self.ClassName
end

function GridLayout.new(): GridLayout
	local self: GridLayout = setmetatable({}, GridLayout)

	self.ClassName = 'NovaUI.GridLayout'
	self.Instance = Instance.new('UIGridLayout')

	return self
end

function GridLayout.SetAdornee(self: GridLayout, adornee: GuiObject?)
	if self.AdorneeConnection then
		self.AdorneeConnection:Disconnect()
	end

	self.Adornee = adornee
	self.Instance.Parent = adornee

	self.AdorneeConnection = adornee.Destroying:Once(function()
		self:Destroy()
	end)
end

function GridLayout.Destroy(self: GridLayout)
	self.Instance:Destroy()
end

return GridLayout
