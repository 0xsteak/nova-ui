local Blueprint = require(script.Parent.Parent.Classes.Blueprint)
local ThemeService = require(script.Parent.Parent.Services.ThemeService)
local TableUtils = require(script.Parent.Parent.Utils.TableUtils)
local Signal = require(script.Parent.Parent.Packages.Signal)
local UserInputService = game:GetService('UserInputService')
local GuiInputService = require(script.Parent.Parent.Services.GuiInputService)
local Transition = require(script.Parent.Parent.Services.TransitionService.Transition)

type base = Frame & {
	View: ScrollingFrame,
	VerticalScrollBar: Frame & {
		Track: Frame,
		Thumb: Frame,
	},
	HorizontalScrollBar: Frame & {
		Track: Frame,
		Thumb: Frame,
	},
}

type ScrollViewProps = {
	Base: base,
	ScrollingDirection: Enum.ScrollingDirection,
	ScrollingEnabled: boolean,
	ScrollBarThickness: number,
	Transitions: {
		ShowVScrollBar: Transition.Transition,
		HideVScrollBar: Transition.Transition,
		ShowHScrollBar: Transition.Transition,
		HideHScrollBar: Transition.Transition,
	},
	_connections: { RBXScriptConnection },
	_verticalHideThread: thread?,
	_horizontalHideThread: thread?,
}

type ScrollViewOptions = {
	ScrollingDirection: Enum.ScrollingDirection?,
	ScrollingEnabled: boolean?,
	ScrollBarThickness: number?,
	CanvasSize: UDim2?,
}

local ScrollView = {}
ScrollView.__index = ScrollView

ScrollView.ClassName = 'NovaUI.ScrollView'

export type ScrollView = typeof(setmetatable({} :: ScrollViewProps, ScrollView))

function ScrollView.__tostring(self: ScrollView)
	return ScrollView.ClassName
end

local TRACK_TRANSPARENCY = 0.9
local THUMB_TRANSPARENCY = 0.8

local TWEEN_INFO = TweenInfo.new(0.25, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)

local BaseBlueprint = Blueprint.new({
	ClassName = 'Frame',
	Name = 'ScrollView',
	Active = true,
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	{
		ClassName = 'ScrollingFrame',
		Name = 'View',
		Active = true,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 1, 0),
		CanvasSize = UDim2.new(),
		ScrollBarThickness = 0,
	},
	{
		ClassName = 'Frame',
		Name = 'VerticalScrollBar',
		Active = true,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		{
			ClassName = 'Frame',
			Name = 'Track',
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Size = UDim2.fromScale(1, 1),
			{
				ClassName = 'UICorner',
				CornerRadius = UDim.new(1, 0),
			},
		},
		{
			ClassName = 'Frame',
			Name = 'Thumb',
			Active = true,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 0),
			{
				ClassName = 'UICorner',
				CornerRadius = UDim.new(1, 0),
			},
		},
	},
	{
		ClassName = 'Frame',
		Name = 'HorizontalScrollBar',
		Active = true,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		{
			ClassName = 'Frame',
			Name = 'Track',
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Size = UDim2.fromScale(1, 1),
			{
				ClassName = 'UICorner',
				CornerRadius = UDim.new(1, 0),
			},
		},
		{
			ClassName = 'Frame',
			Name = 'Thumb',
			Active = true,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 0),
			{
				ClassName = 'UICorner',
				CornerRadius = UDim.new(1, 0),
			},
		},
	},
})

local function updateVerticalScrollBar(self: ScrollView)
	local base = self.Base
	local view = base.View
	local scrollBar = base.VerticalScrollBar
	local scrollBarThumb = scrollBar.Thumb

	local canvasSizeY = view.AbsoluteCanvasSize.Y
	local percent = view.CanvasPosition.Y / (view.AbsoluteCanvasSize.Y - view.AbsoluteWindowSize.Y)

	if canvasSizeY <= view.AbsoluteWindowSize.Y then
		scrollBar.Visible = false
	else
		scrollBar.Visible = true
	end

	scrollBarThumb.Size = UDim2.new(1, 0, 0, view.AbsoluteWindowSize.Y / canvasSizeY * scrollBar.AbsoluteSize.Y)
	scrollBarThumb.Position = UDim2.new(0, 0, 0, (scrollBar.AbsoluteSize.Y - scrollBarThumb.AbsoluteSize.Y) * percent)
end

local function updateHorizontalScrollBar(self: ScrollView)
	local base = self.Base
	local view = base.View
	local scrollBar = base.HorizontalScrollBar
	local scrollBarThumb = scrollBar.Thumb

	local canvasSizeX = view.AbsoluteCanvasSize.X
	local percent = view.CanvasPosition.X / (view.AbsoluteCanvasSize.X - view.AbsoluteWindowSize.X)

	if canvasSizeX <= view.AbsoluteWindowSize.X then
		scrollBar.Visible = false
	else
		scrollBar.Visible = true
	end

	scrollBarThumb.Size = UDim2.new(0, view.AbsoluteWindowSize.X / canvasSizeX * scrollBar.AbsoluteSize.X, 1, 0)
	scrollBarThumb.Position = UDim2.new(0, (scrollBar.AbsoluteSize.X - scrollBarThumb.AbsoluteSize.X) * percent, 0, 0)
end

local DefaultOptions: ScrollViewOptions = {
	ScrollingDirection = Enum.ScrollingDirection.Y,
	ScrollingEnabled = true,
	ScrollBarThickness = 4,
	CanvasSize = UDim2.new(),
}

function ScrollView.new(options: ScrollViewOptions?): ScrollView
	options = TableUtils.Merge(DefaultOptions, options)

	local self: ScrollView = setmetatable({}, ScrollView)

	local base = BaseBlueprint:Build() :: base
	local view = base.View
	local vScrollBar = base.VerticalScrollBar
	local vScrollBarTrack = vScrollBar.Track
	local vScrollBarThumb = vScrollBar.Thumb
	local hScrollBar = base.HorizontalScrollBar
	local hScrollBarTrack = hScrollBar.Track
	local hScrollBarThumb = hScrollBar.Thumb

	self.Base = base
	self._connections = {}

	self:SetScrollingDirection(options.ScrollingDirection)
	self:SetScrollingEnabled(options.ScrollingEnabled)
	self:SetScrollBarThickness(options.ScrollBarThickness)
	self:SetCanvasSize(options.CanvasSize)

	ThemeService.Bind(vScrollBar, 'Foreground', 'BackgroundColor3')
	ThemeService.Bind(vScrollBarThumb, 'Foreground', 'BackgroundColor3')
	ThemeService.Bind(hScrollBar, 'Foreground', 'BackgroundColor3')
	ThemeService.Bind(hScrollBarThumb, 'Foreground', 'BackgroundColor3')

	ThemeService.Update()

	local transitions = {
		ShowVScrollBar = Transition.new({
			[vScrollBarTrack] = {
				BackgroundTransparency = TRACK_TRANSPARENCY,
			},
			[vScrollBarThumb] = {
				BackgroundTransparency = THUMB_TRANSPARENCY,
			},
		}, TWEEN_INFO),
		HideVScrollBar = Transition.new({
			[vScrollBarTrack] = {
				BackgroundTransparency = 1,
			},
			[vScrollBarThumb] = {
				BackgroundTransparency = 1,
			},
		}, TWEEN_INFO),
		ShowHScrollBar = Transition.new({
			[hScrollBarTrack] = {
				BackgroundTransparency = TRACK_TRANSPARENCY,
			},
			[hScrollBarThumb] = {
				BackgroundTransparency = THUMB_TRANSPARENCY,
			},
		}, TWEEN_INFO),
		HideHScrollBar = Transition.new({
			[hScrollBarTrack] = {
				BackgroundTransparency = 1,
			},
			[hScrollBarThumb] = {
				BackgroundTransparency = 1,
			},
		}, TWEEN_INFO),
	}
	self.Transitions = transitions

	GuiInputService.Register(vScrollBar, { RequireOnTop = { IgnoreList = { vScrollBarTrack } } })
	GuiInputService.Register(vScrollBarThumb, { RequireOnTop = true })
	GuiInputService.Register(vScrollBarTrack, { RequireOnTop = { IgnoreList = { vScrollBarThumb } } })
	GuiInputService.Register(hScrollBar, { RequireOnTop = { IgnoreList = { hScrollBarTrack } } })
	GuiInputService.Register(hScrollBarThumb, { RequireOnTop = true })
	GuiInputService.Register(hScrollBarTrack, { RequireOnTop = { IgnoreList = { hScrollBarThumb } } })
	local vTrackMouseEnter = GuiInputService.AddEvent(vScrollBarTrack, 'MouseEnter')
	local vTrackMouseLeave = GuiInputService.AddEvent(vScrollBarTrack, 'MouseLeave')
	local vScrollBarInputBegan = GuiInputService.AddEvent(vScrollBar, 'InputBegan')
	local vThumbInputBegan = GuiInputService.AddEvent(vScrollBarThumb, 'InputBegan')
	local hTrackMouseEnter = GuiInputService.AddEvent(hScrollBarTrack, 'MouseEnter')
	local hTrackMouseLeave = GuiInputService.AddEvent(hScrollBarTrack, 'MouseLeave')
	local hScrollBarInputBegan = GuiInputService.AddEvent(hScrollBar, 'InputBegan')
	local hThumbInputBegan = GuiInputService.AddEvent(hScrollBarThumb, 'InputBegan')

	local vScrollBarVisible = false
	local hScrollBarVisible = false

	local VScrollBarDragEnd = Signal.new()
	local HScrollBarDragEnd = Signal.new()

	local autoUpdateLocked = false
	local dragging = false
	local dragDirection: 'X' | 'Y'
	local startPos: Vector2
	local startMousePos: Vector3

	local function updateVScrollBarInput(mousePos: Vector3)
		if self.ScrollingDirection == Enum.ScrollingDirection.X then
			return
		end

		local newValue = math.clamp(
			startPos.Y - vScrollBar.AbsolutePosition.Y + mousePos.Y - startMousePos.Y,
			0,
			vScrollBar.AbsoluteSize.Y - vScrollBarThumb.AbsoluteSize.Y
		)
		vScrollBarThumb.Position = UDim2.new(0, 0, 0, newValue)
		view.CanvasPosition = Vector2.new(
			view.CanvasPosition.X,
			newValue
				/ (vScrollBar.AbsoluteSize.Y - vScrollBarThumb.AbsoluteSize.Y)
				* (view.AbsoluteCanvasSize.Y - view.AbsoluteWindowSize.Y)
		)
	end

	local function updateHScrollBarInput(mousePos: Vector3)
		if self.ScrollingDirection == Enum.ScrollingDirection.Y then
			return
		end

		local newValue = math.clamp(
			startPos.X - hScrollBar.AbsolutePosition.X + mousePos.X - startMousePos.X,
			0,
			hScrollBar.AbsoluteSize.X - hScrollBarThumb.AbsoluteSize.X
		)
		hScrollBarThumb.Position = UDim2.new(0, newValue, 0, 0)
		view.CanvasPosition = Vector2.new(
			newValue
				/ (hScrollBar.AbsoluteSize.X - hScrollBarThumb.AbsoluteSize.X)
				* (view.AbsoluteCanvasSize.X - view.AbsoluteWindowSize.X),
			view.CanvasPosition.Y
		)
	end

	local function showVScrollBar()
		if self.ScrollingDirection == Enum.ScrollingDirection.X then
			return
		end

		if self._verticalHideThread then
			task.cancel(self._verticalHideThread)
		end

		vScrollBarVisible = true

		transitions.ShowVScrollBar:Play()
	end

	local function _hideVScrollBarFunc()
		transitions.HideVScrollBar:Play()
	end

	local function hideVScrollBar()
		vScrollBarVisible = false
		self._verticalHideThread = task.delay(1, _hideVScrollBarFunc)
	end

	local function showHScrollBar()
		if self.ScrollingDirection == Enum.ScrollingDirection.Y then
			return
		end

		if self._horizontalHideThread then
			task.cancel(self._horizontalHideThread)
		end

		hScrollBarVisible = true

		transitions.ShowHScrollBar:Play()
	end

	local function _hideHScrollBarFunc()
		self.Transitions.HideHScrollBar:Play()
	end

	local function hideHScrollBar()
		hScrollBarVisible = false
		self._horizontalHideThread = task.delay(1, _hideHScrollBarFunc)
	end

	local function updateTheseScrollBars()
		if autoUpdateLocked then
			return
		end
		updateVerticalScrollBar(self)
		updateHorizontalScrollBar(self)

		if not vScrollBarVisible then
			showVScrollBar()
			hideVScrollBar()
		end

		if not hScrollBarVisible then
			showHScrollBar()
			hideHScrollBar()
		end
	end

	view:GetPropertyChangedSignal('CanvasPosition'):Connect(updateTheseScrollBars)
	view:GetPropertyChangedSignal('AbsoluteCanvasSize'):Connect(updateTheseScrollBars)

	vTrackMouseEnter:Connect(showVScrollBar)
	vTrackMouseLeave:Connect(function()
		if dragging and dragDirection == 'Y' then
			VScrollBarDragEnd:Wait()
		end

		hideVScrollBar()
	end)

	vScrollBarInputBegan:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			and self.ScrollingDirection ~= Enum.ScrollingDirection.X
		then
			vScrollBarThumb.Position = UDim2.new(
				0,
				0,
				0,
				input.Position.Y - vScrollBar.AbsolutePosition.Y - (vScrollBarThumb.AbsoluteSize.Y * 0.5)
			)

			dragging = true
			dragDirection = 'Y'
			startPos = vScrollBarThumb.AbsolutePosition
			startMousePos = input.Position
			view.ScrollingEnabled = false
			autoUpdateLocked = true

			local connection: RBXScriptConnection
			connection = input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
					view.ScrollingEnabled = self.ScrollingEnabled
					autoUpdateLocked = false
					connection:Disconnect()
					VScrollBarDragEnd:Fire()
				end
			end)

			updateVScrollBarInput(input.Position)
		end
	end)

	vThumbInputBegan:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			dragDirection = 'Y'
			startPos = vScrollBarThumb.AbsolutePosition
			startMousePos = input.Position
			view.ScrollingEnabled = false
			autoUpdateLocked = true

			local connection: RBXScriptConnection
			connection = input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
					view.ScrollingEnabled = self.ScrollingEnabled
					autoUpdateLocked = false
					connection:Disconnect()
					VScrollBarDragEnd:Fire()
				end
			end)
		end
	end)

	hTrackMouseEnter:Connect(showHScrollBar)
	hTrackMouseLeave:Connect(function()
		if dragging and dragDirection == 'X' then
			HScrollBarDragEnd:Wait()
		end

		hideHScrollBar()
	end)

	hScrollBarInputBegan:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			and self.ScrollingDirection ~= Enum.ScrollingDirection.Y
		then
			hScrollBarThumb.Position = UDim2.new(
				0,
				input.Position.X - hScrollBar.AbsolutePosition.X - (hScrollBarThumb.AbsoluteSize.X * 0.5),
				0,
				0
			)

			dragging = true
			dragDirection = 'X'
			startPos = hScrollBarThumb.AbsolutePosition
			startMousePos = input.Position
			view.ScrollingEnabled = false
			autoUpdateLocked = true

			local connection: RBXScriptConnection
			connection = input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
					view.ScrollingEnabled = self.ScrollingEnabled
					autoUpdateLocked = false
					connection:Disconnect()
					HScrollBarDragEnd:Fire()
				end
			end)

			updateHScrollBarInput(input.Position)
		end
	end)

	hThumbInputBegan:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			dragDirection = 'X'
			startPos = hScrollBarThumb.AbsolutePosition
			startMousePos = input.Position
			view.ScrollingEnabled = false
			autoUpdateLocked = true

			local connection: RBXScriptConnection
			connection = input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
					view.ScrollingEnabled = self.ScrollingEnabled
					autoUpdateLocked = false
					connection:Disconnect()
					HScrollBarDragEnd:Fire()
				end
			end)
		end
	end)

	self._connections[1] = UserInputService.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement and dragging then
			if dragDirection == 'Y' then
				updateVScrollBarInput(input.Position)
			else
				updateHScrollBarInput(input.Position)
			end
		end
	end)

	updateTheseScrollBars()

	return self
end

function ScrollView.SetScrollingDirection(self: ScrollView, direction: Enum.ScrollingDirection)
	self.ScrollingDirection = direction
	self.Base.View.ScrollingDirection = direction
end

function ScrollView.SetScrollingEnabled(self: ScrollView, enabled: boolean)
	self.ScrollingEnabled = enabled
	self.Base.View.ScrollingEnabled = enabled
end

function ScrollView.SetScrollBarThickness(self: ScrollView, thickness: number)
	self.ScrollBarThickness = thickness

	local vScrollBar = self.Base.VerticalScrollBar
	local hScrollBar = self.Base.HorizontalScrollBar

	vScrollBar.Position = UDim2.new(1, -thickness - 5, 0, 10)
	vScrollBar.Size = UDim2.new(0, thickness, 1, -20)
	hScrollBar.Position = UDim2.new(0, 10, 1, -thickness - 5)
	hScrollBar.Size = UDim2.new(1, -25, 0, thickness)
end

function ScrollView.SetCanvasSize(self: ScrollView, size: UDim2)
	self.Base.View.CanvasSize = size
end

function ScrollView.SetCanvasPosition(self: ScrollView, position: Vector2)
	self.Base.View.CanvasPosition = position
end

function ScrollView.SetParent(self: ScrollView, parent: Instance)
	self.Base.Parent = parent
end

function ScrollView.Destroy(self: ScrollView)
	local base = self.Base

	for _, connection in self._connections do
		connection:Disconnect()
	end
	if self._verticalHideThread then
		task.cancel(self._verticalHideThread)
	end
	if self._horizontalHideThread then
		task.cancel(self._horizontalHideThread)
	end

	base:Destroy()
end

return ScrollView
