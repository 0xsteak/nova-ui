local Signal = require(script.Parent.Parent.Packages.Signal)
local UserInputService = game:GetService('UserInputService')

type DragControllerProps = {
	Target: GuiObject,
	DragHandle: GuiObject,
	Enabled: boolean,
	Locked: boolean,
	IsDragging: boolean,
	_dragOffset: Vector2,
	_dragChanged: Signal.Signal<UDim2>,
	_connections: { RBXScriptConnection },
}

local DragController = {}
DragController.__index = DragController

DragController.ClassName = 'NovaUI.DragController'

export type DragController = typeof(setmetatable({} :: DragControllerProps, DragController))

function DragController.__tostring(self: DragController)
	return DragController.ClassName
end

local Controllers: { DragController } = {}
local beganInputType = if UserInputService.TouchEnabled
	then Enum.UserInputType.Touch
	else Enum.UserInputType.MouseButton1
local changedInputType = if UserInputService.TouchEnabled
	then Enum.UserInputType.Touch
	else Enum.UserInputType.MouseMovement

function DragController.new(target: GuiObject, dragHandle: GuiObject): DragController
	local self: DragController = setmetatable({}, DragController)

	self.Target = target
	self.DragHandle = dragHandle
	self.Enabled = true
	self.Locked = false
	self.IsDragging = false
	self._dragChanged = Signal.new()

	local connections: { RBXScriptConnection } = {}

	connections[1] = dragHandle.InputBegan:Connect(function(input)
		if input.UserInputType == beganInputType and self.Enabled and not self.Locked then
			if beganInputType == Enum.UserInputType.Touch and input.UserInputState ~= Enum.UserInputState.Begin then
				return
			end

			self._dragOffset = Vector2.new(
				target.AbsolutePosition.X - input.Position.X + target.AbsoluteSize.X * target.AnchorPoint.X,
				target.AbsolutePosition.Y - input.Position.Y + target.AbsoluteSize.Y * target.AnchorPoint.Y
			)

			self.IsDragging = true

			local connection: RBXScriptConnection
			connection = input.Changed:Connect(function()
				if input.UserInputState ~= Enum.UserInputState.End then
					return
				end

				self.IsDragging = false
				connection:Disconnect()
			end)
		end
	end)

	connections[2] = target.Destroying:Once(function()
		self:Destroy()
	end)

	self._connections = connections

	table.insert(Controllers, 1, self)

	return self
end

function DragController.Destroy(self: DragController)
	for _, connection in self._connections do
		connection:Disconnect()
	end

	local index = table.find(Controllers, self)
	if index then
		table.remove(Controllers, index)
	end
end

UserInputService.InputChanged:Connect(function(input)
	if input.UserInputType ~= changedInputType then
		return
	end

	for _, controller in Controllers do
		if not controller.IsDragging then
			continue
		end

		local dragOffset = controller._dragOffset
		local newPos = UDim2.fromOffset(input.Position.X + dragOffset.X, input.Position.Y + dragOffset.Y)

		controller.Target.Position = newPos
		controller._dragChanged:Fire(newPos)

		return
	end
end)

return DragController
