local Signal = require(script.Parent.Parent.Packages.Signal)
local Players = game:GetService('Players')
local UserInputService = game:GetService('UserInputService')

type Directions = {
	Left: boolean,
	Right: boolean,
	Top: boolean,
	Bottom: boolean,
	TopLeft: boolean,
	BottomLeft: boolean,
	TopRight: boolean,
	BottomRight: boolean,
}

type ResizeControllerProps = {
	Adornee: GuiObject,
	Directions: Directions,
	Enabled: boolean,
	Locked: boolean,
	IsResizing: boolean,
	ResizeDirection: Direction?,
	StartInfo: {
		Position: Vector2,
		Size: Vector2,
		MousePos: Vector3,
	},
	ResizeMin: Vector2,
	ResizeMax: Vector2,
	ResizeChanged: Signal.Signal<UDim2, UDim2>,
	Connections: { RBXScriptConnection },
}

type Edges = {
	Left: number,
	Right: number,
	Top: number,
	Bottom: number,
}

type Direction = 'Left' | 'Right' | 'Top' | 'Bottom' | 'TopLeft' | 'BottomLeft' | 'TopRight' | 'BottomRight'

local ResizeController = {}
ResizeController.__index = ResizeController

ResizeController.ClassName = 'NovaUI.ResizeController'

export type ResizeController = typeof(setmetatable({} :: ResizeControllerProps, ResizeController))

function ResizeController.__tostring(self: ResizeController)
	return ResizeController.ClassName
end

local Controllers: { ResizeController } = {}

local function setMouseIcon(icon: string)
	local localPlayer = Players.LocalPlayer
	if localPlayer then
		localPlayer:GetMouse().Icon = icon
	end
end

local CursorIcons: { [Direction]: string } = {
	Left = 'rbxasset://textures/StudioUIEditor/icon_resize2.png',
	Right = 'rbxasset://textures/StudioUIEditor/icon_resize2.png',
	Top = 'rbxasset://textures/StudioUIEditor/icon_resize4.png',
	Bottom = 'rbxasset://textures/StudioUIEditor/icon_resize4.png',
	TopLeft = 'rbxasset://textures/StudioUIEditor/icon_resize3.png',
	BottomLeft = 'rbxasset://textures/StudioUIEditor/icon_resize1.png',
	TopRight = 'rbxasset://textures/StudioUIEditor/icon_resize1.png',
	BottomRight = 'rbxasset://textures/StudioUIEditor/icon_resize3.png',
}
local HandleSize = 10

local function isInArea(mousePos: Vector2 | Vector3, xMin, xMax, yMin, yMax): boolean
	return mousePos.X >= xMin and mousePos.X <= xMax and mousePos.Y >= yMin and mousePos.Y <= yMax
end

local CheckArea = {
	Left = function(mousePos: Vector2 | Vector3, edges: Edges): boolean
		return isInArea(mousePos, edges.Left - HandleSize, edges.Left, edges.Top, edges.Bottom)
	end,
	Right = function(mousePos: Vector2 | Vector3, edges: Edges): boolean
		return isInArea(mousePos, edges.Right, edges.Right + HandleSize, edges.Top, edges.Bottom)
	end,
	Top = function(mousePos: Vector2 | Vector3, edges: Edges): boolean
		return isInArea(mousePos, edges.Left, edges.Right, edges.Top - HandleSize, edges.Top)
	end,
	Bottom = function(mousePos: Vector2 | Vector3, edges: Edges): boolean
		return isInArea(mousePos, edges.Left, edges.Right, edges.Bottom, edges.Bottom + HandleSize)
	end,
	TopLeft = function(mousePos: Vector2 | Vector3, edges: Edges): boolean
		return isInArea(mousePos, edges.Left - HandleSize, edges.Left, edges.Top - HandleSize, edges.Top)
	end,
	BottomLeft = function(mousePos: Vector2 | Vector3, edges: Edges): boolean
		return isInArea(mousePos, edges.Left - HandleSize, edges.Left, edges.Bottom, edges.Bottom + HandleSize)
	end,
	TopRight = function(mousePos: Vector2 | Vector3, edges: Edges): boolean
		return isInArea(mousePos, edges.Right, edges.Right + HandleSize, edges.Top - HandleSize, edges.Top)
	end,
	BottomRight = function(mousePos: Vector2 | Vector3, edges: Edges): boolean
		return isInArea(mousePos, edges.Right, edges.Right + HandleSize, edges.Bottom, edges.Bottom + HandleSize)
	end,
}

local function getEdges(object: GuiObject): Edges
	return {
		Left = object.AbsolutePosition.X,
		Right = object.AbsolutePosition.X + object.AbsoluteSize.X,
		Top = object.AbsolutePosition.Y,
		Bottom = object.AbsolutePosition.Y + object.AbsoluteSize.Y,
	}
end

local function getDirection(mousePos: Vector3, object: GuiObject, directions: Directions): Direction?
	local edges = getEdges(object)

	-- Corners are first because otherwise the other edges will always be the first to show up
	if CheckArea.TopLeft(mousePos, edges) and directions.TopLeft then
		return 'TopLeft'
	elseif CheckArea.BottomLeft(mousePos, edges) and directions.BottomLeft then
		return 'BottomLeft'
	elseif CheckArea.TopRight(mousePos, edges) and directions.TopRight then
		return 'TopRight'
	elseif CheckArea.BottomRight(mousePos, edges) and directions.BottomRight then
		return 'BottomRight'
	elseif CheckArea.Left(mousePos, edges) and directions.Left then
		return 'Left'
	elseif CheckArea.Right(mousePos, edges) and directions.Right then
		return 'Right'
	elseif CheckArea.Top(mousePos, edges) and directions.Top then
		return 'Top'
	elseif CheckArea.Bottom(mousePos, edges) and directions.Bottom then
		return 'Bottom'
	end

	return nil
end

local function getOffset(direction: Direction, mousePos: Vector3, startPos: Vector2): (Vector2, Vector2)
	if direction == 'TopLeft' then
		return Vector2.new(1, 1), Vector2.new(startPos.X - mousePos.X, startPos.Y - mousePos.Y)
	elseif direction == 'BottomRight' then
		return Vector2.new(0, 0), Vector2.new(mousePos.X - startPos.X, mousePos.Y - startPos.Y)
	elseif direction == 'TopRight' then
		return Vector2.new(0, 1), Vector2.new(mousePos.X - startPos.X, startPos.Y - mousePos.Y)
	elseif direction == 'BottomLeft' then
		return Vector2.new(1, 0), Vector2.new(startPos.X - mousePos.X, mousePos.Y - startPos.Y)
	elseif direction == 'Left' then
		return Vector2.new(1, 0), Vector2.new(startPos.X - mousePos.X, 0)
	elseif direction == 'Right' then
		return Vector2.new(0, 0), Vector2.new(mousePos.X - startPos.X, 0)
	elseif direction == 'Top' then
		return Vector2.new(0, 1), Vector2.new(0, startPos.Y - mousePos.Y)
	elseif direction == 'Bottom' then
		return Vector2.new(0, 0), Vector2.new(0, mousePos.Y - startPos.Y)
	end

	return Vector2.zero, Vector2.zero
end

function ResizeController.new(adornee: GuiObject): ResizeController
	local self: ResizeController = setmetatable({}, ResizeController)

	self.Adornee = adornee
	self.Directions = {
		Left = true,
		Right = true,
		Top = true,
		Bottom = true,
		TopLeft = true,
		BottomLeft = true,
		TopRight = true,
		BottomRight = true,
	}
	self.Enabled = true
	self.Locked = false
	self.IsResizing = false
	self.ResizeDirection = nil
	self.StartInfo = {}
	self.ResizeMin = Vector2.new(0, 0)
	self.ResizeMax = Vector2.new(math.huge, math.huge)
	self.ResizeChanged = Signal.new()

	local connections: { RBXScriptConnection } = {}

	connections[1] = UserInputService.InputBegan:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			and self.Enabled
			and not self.Locked
			and self.ResizeDirection
		then
			local startInfo = self.StartInfo

			startInfo.Position = adornee.AbsolutePosition
			startInfo.Size = adornee.AbsoluteSize
			startInfo.MousePos = input.Position

			self.IsResizing = true

			local connection: RBXScriptConnection
			connection = input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					self.IsResizing = false
					connection:Disconnect()
				end
			end)
		end
	end)

	connections[2] = adornee.Destroying:Once(function()
		self:Destroy()
	end)

	self.Connections = connections

	table.insert(Controllers, 1, self)

	return self
end

function ResizeController.Destroy(self: ResizeController)
	for _, connection in self.Connections do
		connection:Disconnect()
	end

	local index = table.find(Controllers, self)
	if index then
		table.remove(Controllers, index)
	end
end

local lastDirection

UserInputService.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement then
		for _, controller in Controllers do
			if not controller.Enabled or controller.Locked or not controller.Adornee.Visible then
				continue
			end

			if controller.IsResizing then
				local adornee = controller.Adornee
				local resizeDirection = controller.ResizeDirection
				local startInfo = controller.StartInfo
				local startPos = startInfo.Position
				local startSize = startInfo.Size
				local startMousePos = startInfo.MousePos
				local resizeMin = controller.ResizeMin
				local resizeMax = controller.ResizeMax
				local resizePoint, offset = getOffset(resizeDirection, input.Position, startMousePos)

				local offsetX = math.clamp(offset.X, resizeMin.X - startSize.X, resizeMax.X - startSize.X)
				local offsetY = math.clamp(offset.Y, resizeMin.Y - startSize.Y, resizeMax.Y - startSize.Y)

				-- using math.round for smoother resize

				local newSizeX = math.round(startSize.X + offsetX)
				local newSizeY = math.round(startSize.Y + offsetY)

				local newPos = UDim2.fromOffset(
					math.round(startPos.X - offsetX * resizePoint.X + (newSizeX * adornee.AnchorPoint.X)),
					math.round(startPos.Y - offsetY * resizePoint.Y + (newSizeY * adornee.AnchorPoint.Y))
				)
				local newSize = UDim2.fromOffset(newSizeX, newSizeY)

				adornee.Position = newPos
				adornee.Size = newSize

				controller.ResizeChanged:Fire(newPos, newSize)

				return
			end

			local direction = getDirection(input.Position, controller.Adornee, controller.Directions)
			controller.ResizeDirection = direction
			if direction then
				lastDirection = direction
				setMouseIcon(CursorIcons[direction])
				return
			end
		end

		if lastDirection then
			lastDirection = nil
			setMouseIcon('')
		end
	end
end)

return ResizeController
