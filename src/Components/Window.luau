local IconButton = require(script.Parent.Buttons.IconButton)
local Icon = require(script.Parent.Parent.Classes.Icon)
local Blueprint = require(script.Parent.Parent.Classes.Blueprint)
local GuiUtils = require(script.Parent.Parent.Utils.GuiUtils)
local TableUtils = require(script.Parent.Parent.Utils.TableUtils)
local Registry = require(script.Parent.Parent.Registry)
local ThemeService = require(script.Parent.Parent.Services.ThemeService)
local DragController = require(script.Parent.Parent.Controllers.DragController)
local ResizeController = require(script.Parent.Parent.Controllers.ResizeController)
local Container = require(script.Parent.Container)
local Preferences = require(script.Parent.Parent.Registry.Preferences)
local TransitionService = require(script.Parent.Parent.Services.TransitionService)
local Transition = require(script.Parent.Parent.Services.TransitionService.Transition)
local TransitionGroup = require(script.Parent.Parent.Services.TransitionService.TransitionGroup)

type instance = CanvasGroup & {
	TopBar: Frame & {
		Title: TextLabel,
		Icon: ImageLabel,
		Buttons: Frame & {
			UIListLayout: UIListLayout,
			UIPadding: UIPadding,
		},
		DragHandle: Frame,
	},
	Content: Frame,
	UIScale: UIScale,
	UIShadow: UIShadow,
}

type WindowProps = {
	Instance: instance,
	Title: string,
	Icon: Icon.Icon?,
	Position: UDim2,
	Size: UDim2,
	OriginalSize: UDim2,
	OriginalPosition: UDim2,
	TopBarButtons: { [string]: IconButton.IconButton },
	DragController: DragController.DragController,
	ResizeController: ResizeController.ResizeController,
	ResizeMinAuto: boolean,
	Content: Container.Container,
	Transitions: {
		Maximize: Transition.Transition,
		Restore: Transition.Transition,
	},
	TransitionGroups: {
		Show: TransitionGroup.TransitionGroup,
		Hide: TransitionGroup.TransitionGroup,
	},
	Hidden: boolean,
}

export type WindowOptions = {
	Title: string?,
	Icon: Icon.Icon?,
	Position: UDim2?,
	Size: UDim2?,
	Draggable: boolean?,
	Resizable: boolean?,
}

local Window = {}
Window.__index = Window

Window.ClassName = 'NovaUI.Window'

export type Window = typeof(setmetatable({} :: WindowProps, Window))

function Window.__tostring(self: Window)
	return Window.ClassName
end

local _basePreset = {
	Time = 0.25,
	EasingStyle = Enum.EasingStyle.Cubic,
	EasingDirection = Enum.EasingDirection.Out,
}
local ShowPreset: TransitionGroup.Preset = {
	_base = _basePreset,
	Window = {
		PropertyTable = {
			GroupTransparency = 0,
		} :: Transition.PropertyTable<CanvasGroup>,
	},
	UIScale = {
		PropertyTable = {
			Scale = 1,
		} :: Transition.PropertyTable<UIScale>,
	},
	UIShadow = {
		PropertyTable = {
			Transparency = 0.5,
		},
	},
}
local HidePreset: TransitionGroup.Preset = {
	_base = _basePreset,
	Window = {
		PropertyTable = {
			GroupTransparency = 1,
		} :: Transition.PropertyTable<CanvasGroup>,
	},
	UIScale = {
		PropertyTable = {
			Scale = 0.85,
		} :: Transition.PropertyTable<UIScale>,
	},
	UIShadow = {
		PropertyTable = {
			Transparency = 1,
		},
	},
}
local MaximizePreset: Transition.Preset = table.clone(_basePreset)
MaximizePreset.PropertyTable = {
	Position = UDim2.new(0.5, 0, 0.5, 0),
	Size = UDim2.new(1, 0, 1, 0),
} :: Transition.PropertyTable<CanvasGroup>

local BaseBlueprint = Blueprint.new({
	ClassName = 'CanvasGroup',
	Active = true,
	AnchorPoint = Vector2.new(0.5, 0.5),
	GroupTransparency = 1,
	Visible = false,
	{
		ClassName = 'UIScale',
		Scale = 0.85,
	},
	{
		ClassName = 'UICorner',
		CornerRadius = UDim.new(0, 8),
	},
	{
		ClassName = 'UIShadow',
		BlurRadius = UDim.new(0, 20),
		Transparency = 1,
	} :: Blueprint.BlueprintData<UIShadow>,
	{
		ClassName = 'Frame',
		Name = 'TopBar',
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 30),
		{
			ClassName = 'Frame',
			Name = 'DragHandle',
			BackgroundTransparency = 1,
		},
		{
			ClassName = 'ImageLabel',
			Name = 'Icon',
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 10, 0.5, 0),
			Size = UDim2.new(0, 16, 0, 16),
		},
		{
			ClassName = 'TextLabel',
			Name = 'Title',
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 36, 0, 0),
			TextSize = 14,
			TextTruncate = Enum.TextTruncate.AtEnd,
			TextXAlignment = Enum.TextXAlignment.Left,
		},
		{
			ClassName = 'Frame',
			Name = 'Buttons',
			AnchorPoint = Vector2.new(1, 0),
			BackgroundTransparency = 1,
			Position = UDim2.new(1, 0, 0, 0),
			{
				ClassName = 'UIListLayout',
				Padding = UDim.new(0, 5),
				FillDirection = Enum.FillDirection.Horizontal,
				SortOrder = Enum.SortOrder.LayoutOrder,
				HorizontalAlignment = Enum.HorizontalAlignment.Right,
				VerticalAlignment = Enum.VerticalAlignment.Center,
			},
			{
				ClassName = 'UIPadding',
				PaddingRight = UDim.new(0, 5),
			},
		},
	},
	{
		ClassName = 'Frame',
		Name = 'Content',
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 0, 30),
		Size = UDim2.new(1, 0, 1, -30),
	},
})

local topBarIconsSheet = 'rbxassetid://106110894885348'
local closeIcon = Icon.new(topBarIconsSheet, Vector2.new(16, 16), Vector2.zero)
local maximizeIcon = Icon.new(topBarIconsSheet, Vector2.new(16, 16), Vector2.new(16, 0))
local restoreIcon = Icon.new(topBarIconsSheet, Vector2.new(16, 16), Vector2.new(16, 16))
local minimizeIcon = Icon.new(topBarIconsSheet, Vector2.new(16, 16), Vector2.new(0, 16))

local function maximizeToggle(self: Window, restore: boolean?)
	local buttons = self.TopBarButtons
	local transitions = self.Transitions

	if restore then
		transitions.Maximize:Cancel()
		transitions.Restore:Replay()
	else
		transitions.Restore:Cancel()
		transitions.Maximize:Replay()
	end

	self.DragController.Locked = if restore then false else true
	self.ResizeController.Locked = if restore then false else true

	buttons.Restore.Instance.Visible = if restore then false else true
	buttons.Maximize.Instance.Visible = if restore then true else false
end

local function initTopBarButtons(self: Window)
	local close = self:CreateTopBarButton('Close', closeIcon, function()
		self:Hide()
	end)
	close.Instance.LayoutOrder = 3

	local maximize = self:CreateTopBarButton('Maximize', maximizeIcon, function()
		maximizeToggle(self)
	end)
	maximize.Instance.LayoutOrder = 2

	local restore = self:CreateTopBarButton('Restore', restoreIcon, function()
		maximizeToggle(self, true)
	end)
	restore.Instance.Visible = false
	restore.Instance.LayoutOrder = 2

	local minimize = self:CreateTopBarButton('Minimize', minimizeIcon, function()
		self:Hide()
	end)
	minimize.Instance.LayoutOrder = 1
end

local function updateTopBar(self: Window)
	local topBar = (self.Instance :: instance).TopBar
	local icon = topBar.Icon
	local title = topBar.Title
	local buttons = topBar.Buttons
	local listLayout = buttons.UIListLayout

	local iconSizeX = if icon.Visible then icon.AbsoluteSize.X + 10 else 0
	local contentSizeX = listLayout.AbsoluteContentSize.X
	local newButtonsSizeX = contentSizeX + (if contentSizeX > 0 then 10 else 0)

	buttons.Size = UDim2.new(0, newButtonsSizeX, 1, 0)
	title.Position = UDim2.new(0, iconSizeX + 10, 0, 0)
	topBar.DragHandle.Size = UDim2.new(1, -newButtonsSizeX, 1, 0)
	title.Size = UDim2.new(1, -iconSizeX - 10 - newButtonsSizeX, 1, 0)

	if self.ResizeMinAuto then
		self.ResizeController.ResizeMin = Vector2.new(iconSizeX + 10 + newButtonsSizeX, topBar.AbsoluteSize.Y)
	end
end

local DefaultOptions: WindowOptions = {
	Title = 'Window',
	Position = UDim2.new(0.5, 0, 0.5, 0),
	Size = UDim2.new(0, 640, 0, 480),
	Draggable = true,
	Resizable = true,
}

function Window.new(options: WindowOptions?): Window
	options = TableUtils.Merge(DefaultOptions, options)

	local self: Window = setmetatable({}, Window)

	local instance = BaseBlueprint:Build() :: instance
	local topBar = instance.TopBar
	local icon = topBar.Icon
	local buttons = topBar.Buttons
	local listLayout = buttons.UIListLayout

	local function updateTitleFont()
		topBar.Title.FontFace = Font.new(Preferences.GetFontFamily(), Enum.FontWeight.Medium)
	end
	Preferences.FontFamilyChanged:Connect(updateTitleFont)
	updateTitleFont()

	self.Instance = instance
	self.TopBarButtons = {}
	self.Hidden = false

	local restorePreset: Transition.Preset = table.clone(_basePreset)
	restorePreset.PropertyTable = function()
		return {
			Position = self.OriginalPosition,
			Size = self.OriginalSize,
		} :: Transition.PropertyTable<CanvasGroup>
	end

	local showTransition = TransitionService.CreateGroup(
		{ Window = instance, UIScale = instance.UIScale, UIShadow = instance.UIShadow },
		ShowPreset
	)
	local hideTransition = TransitionService.CreateGroup(
		{ Window = instance, UIScale = instance.UIScale, UIShadow = instance.UIShadow },
		HidePreset
	)
	local maximizeTransition = TransitionService.Create(instance, MaximizePreset)
	local restoreTransition = TransitionService.Create(instance, restorePreset)

	self.TransitionGroups = {
		Show = showTransition,
		Hide = hideTransition,
	}
	self.Transitions = {
		Maximize = maximizeTransition,
		Restore = restoreTransition,
	}

	ThemeService.Bind(instance, 'Background', 'BackgroundColor3')
	ThemeService.Bind(topBar.Title, 'PrimaryText', 'TextColor3')
	ThemeService.Bind(icon, 'Accent', 'ImageColor3')

	ThemeService.Update()

	self:SetTitle(options.Title :: string)
	self:SetIcon(options.Icon)
	self:SetSize(options.Size :: UDim2)
	if not options.Position then
		self:Center()
	else
		self:SetPosition(options.Position)
	end
	self.ResizeMinAuto = true

	initTopBarButtons(self)

	local function updateThisTopBar()
		updateTopBar(self)
	end

	listLayout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(updateThisTopBar)
	topBar:GetPropertyChangedSignal('Size'):Connect(updateThisTopBar)
	icon:GetPropertyChangedSignal('Visible'):Connect(updateThisTopBar)

	local dragController = DragController.new(instance, topBar.DragHandle)
	dragController.Enabled = options.Draggable
	dragController.DragChanged:Connect(function(newPos)
		self.OriginalPosition = newPos
	end)
	self.DragController = dragController

	local resizeController = ResizeController.new(instance)
	resizeController.Enabled = options.Resizable
	resizeController.ResizeMin = Vector2.new()
	resizeController.ResizeChanged:Connect(function(newPos, newSize)
		self.OriginalPosition = newPos
		self.OriginalSize = newSize
	end)
	self.ResizeController = resizeController

	self.Content = Container.fromGuiObject(instance.Content)

	self.Instance.Parent = Registry.GetRootScreenGui()

	updateThisTopBar()

	return self
end

function Window.SetTitle(self: Window, title: string)
	self.Title = title
	self.Instance.TopBar.Title.Text = title
end

function Window.SetIcon(self: Window, icon: Icon.Icon?)
	self.Icon = icon

	local topBarIcon = self.Instance.TopBar.Icon
	if icon then
		icon:ApplyTo(topBarIcon)
		topBarIcon.Visible = true
	else
		topBarIcon.Visible = false
	end

	updateTopBar(self)
end

function Window.SetSize(self: Window, size: UDim2)
	self.Size = size
	self.OriginalSize = size

	self.Instance.Size = size
end

function Window.SetPosition(self: Window, position: UDim2)
	self.Position = position
	self.OriginalPosition = position

	self.Instance.Position = position
end

function Window.Center(self: Window)
	self:SetPosition(GuiUtils.GetCenterPosition(self.Instance))
end

function Window.CreateTopBarButton(
	self: Window,
	name: string,
	icon: Icon.Icon,
	callback: () -> ()
): IconButton.IconButton
	local button = IconButton.new(icon, callback)
	button.Instance.Parent = self.Instance.TopBar.Buttons

	self.TopBarButtons[name] = button

	return button
end

function Window.Show(self: Window)
	local instance = self.Instance
	instance.Visible = true

	local transitionGroups = self.TransitionGroups

	transitionGroups.Hide:CancelAll()
	transitionGroups.Show:ReplayAll()

	self.Hidden = false
end

function Window.Hide(self: Window)
	local instance = self.Instance

	local transitionGroups = self.TransitionGroups
	local hideTransition = transitionGroups.Hide

	transitionGroups.Show:CancelAll()
	hideTransition:ReplayAll()

	hideTransition.Transitions.Window.Completed:Once(function()
		instance.Visible = false
	end)

	self.Hidden = true
end

local function makeModal(self: Window, restore: boolean?)
	self.DragController.Locked = if restore then false else true
	self.ResizeController.Locked = if restore then false else true

	local buttons = self.TopBarButtons

	if restore then
		buttons.Maximize:Enable()
		buttons.Restore:Enable()
		buttons.Minimize:Enable()
	else
		buttons.Maximize:Disable()
		buttons.Restore:Disable()
		buttons.Minimize:Disable()
	end
end

function Window.SetParent(self: Window, parent: Instance)
	if parent:IsA('GuiObject') then
		makeModal(self)
	else
		makeModal(self, true)
	end

	self.Instance.Parent = parent
end

function Window.GetContent(self: Window): GuiObject
	return self.Content.Instance
end

function Window.Destroy(self: Window)
	for _, button in self.TopBarButtons do
		button:Destroy()
	end

	self.Content:Destroy()
	self.Instance:Destroy()
end

return Window
