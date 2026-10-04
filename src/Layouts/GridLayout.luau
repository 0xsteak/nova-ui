type GridLayoutProps = {
	Target: GuiObject?,
	Base: UIGridLayout,
	_targetConnection: RBXScriptConnection,
}

local GridLayout = {}
GridLayout.__index = GridLayout

GridLayout.ClassName = 'NovaUI.GridLayout'

export type GridLayout = typeof(setmetatable({} :: GridLayoutProps, GridLayout))

function GridLayout.__tostring(self: GridLayout)
	return GridLayout.ClassName
end

function GridLayout.new(): GridLayout
	local self: GridLayout = setmetatable({}, GridLayout)

	self.Base = Instance.new('UIGridLayout')

	return self
end

function GridLayout.SetTarget(self: GridLayout, target: GuiObject?)
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

function GridLayout.Destroy(self: GridLayout)
	self.Base:Destroy()
	if self._targetConnection then
		self._targetConnection:Disconnect()
	end
end

return GridLayout
