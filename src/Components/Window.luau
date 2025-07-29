local Icon = require("../Classes/Icon")
local Blueprint = require("../Modules/Blueprint")
local GuiUtils = require("../Utils/GuiUtils")
local TableUtils = require("../Utils/TableUtils")
local Registry = require("../Modules/Registry")
local ThemeService = require("../Modules/ThemeService")
local DragController = require("../Modules/DragController")
local ResizeController = require("../Modules/ResizeController")
local Tweener = require("../Modules/Tweener")
local IconButton = require("./IconButton")

-- -- -- -- --

type WindowImpl = {
    __index: WindowImpl,
    new: (options: WindowOptions) -> Window,
    SetTitle: (self: Window, title: string) -> (),
    SetIcon: (self: Window, icon: Icon.Icon?) -> (),
    SetSize: (self: Window, size: UDim2) -> (),
    SetPosition: (self: Window, position: UDim2) -> (),
    Center: (self: Window) -> (),
    CreateTopBarButton: (self: Window, name: string, icon: Icon.Icon, callback: () -> ()) -> IconButton.IconButton,
    Show: (self: Window) -> (),
    Hide: (self: Window) -> (),
    Destroy: (self: Window) -> ()
}

type instance = CanvasGroup & {
    TopBar: Frame & {
        Title: TextLabel,
        Icon: ImageLabel,
        Buttons: Frame & {
            UIListLayout: UIListLayout,
            UIPadding: UIPadding
        },
        DragHandle: Frame,
    },
    Content: Frame,
    UIScale: UIScale
}

type self = {
    Class: "Window",
    Instance: instance,
    Title: string,
    Icon: Icon.Icon?,
    Position: UDim2,
    Size: UDim2,
    OriginalSize: UDim2,
    OriginalPosition: UDim2,
    TopBarButtons: {[string]: IconButton.IconButton},
    DragController: DragController.DragController,
    ResizeController: ResizeController.ResizeController,
    ResizeMinAuto: boolean
}

export type Window = typeof(setmetatable({} :: self, {} :: WindowImpl))

export type WindowOptions = {
    Title: string?,
    Icon: Icon.Icon?,
    Position: UDim2?,
    Size: UDim2?,
    Draggable: boolean?,
    Resizable: boolean?
}

-- -- -- -- --

local Window = {} :: WindowImpl
Window.__index = Window

local BaseBlueprint: Blueprint.Blueprint = Blueprint.new({
    Class = "CanvasGroup",
    Active = true,
    AnchorPoint = Vector2.new(0.5, 0.5),
    GroupTransparency = 1,
    Visible = false,
    {
        Class = "UIScale",
        Scale = 0.85
    },
    {
        Class = "UICorner",
        CornerRadius = UDim.new(0, 8)
    },
    {
        Class = "Frame",
        Name = "TopBar",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 30),
        {
            Class = "Frame",
            Name = "DragHandle",
            BackgroundTransparency = 1
        },
        {
            Class = "ImageLabel",
            Name = "Icon",
            AnchorPoint = Vector2.new(0, 0.5),
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 10, 0.5, 0),
            Size = UDim2.new(0, 16, 0, 16)
        },
        {
            Class = "TextLabel",
            Name = "Title",
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 36, 0, 0),
            FontFace = Font.new(Registry.Settings.FontId, Enum.FontWeight.Medium),
            TextSize = 14,
            TextTruncate = Enum.TextTruncate.AtEnd,
            TextXAlignment = Enum.TextXAlignment.Left
        },
        {
            Class = "Frame",
            Name = "Buttons",
            AnchorPoint = Vector2.new(1, 0),
            BackgroundTransparency = 1,
            Position = UDim2.new(1, 0, 0, 0),
            {
                Class = "UIListLayout",
                Padding = UDim.new(0, 5),
                FillDirection = Enum.FillDirection.Horizontal,
                SortOrder = Enum.SortOrder.LayoutOrder,
                HorizontalAlignment = Enum.HorizontalAlignment.Right,
                VerticalAlignment = Enum.VerticalAlignment.Center
            },
            {
                Class = "UIPadding",
                PaddingRight = UDim.new(0, 5)
            }
        }
    },
    {
        Class = "Frame",
        Name = "Content",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 30),
        Size = UDim2.new(1, 0, 1, -30)
    }
})

local topBarIconsSheet = "rbxassetid://106110894885348"
local closeIcon = Icon.new(topBarIconsSheet, Vector2.new(16, 16), Vector2.zero)
local maximizeIcon = Icon.new(topBarIconsSheet, Vector2.new(16, 16), Vector2.new(16, 0))
local restoreIcon = Icon.new(topBarIconsSheet, Vector2.new(16, 16), Vector2.new(16, 16))
local minimizeIcon = Icon.new(topBarIconsSheet, Vector2.new(16, 16), Vector2.new(0, 16))

local function maximizeToggle(self: Window, restore: boolean?)
	local instance = self.Instance
	local tweenInfo = Tweener.TweenInfo(0.25, Enum.EasingStyle.Cubic)
	local buttons = self.TopBarButtons

	Tweener.Tween(instance, tweenInfo, "maximize_restore", {
		Position = if restore then self.OriginalPosition else UDim2.new(0.5, 0, 0.5, 0),
		Size = if restore then self.OriginalSize else UDim2.new(1, 0, 1, 0),
	})

	self.DragController.Locked = if restore then false else true
	self.ResizeController.Locked = if restore then false else true

	buttons.Restore.Instance.Visible = if restore then false else true
	buttons.Maximize.Instance.Visible = if restore then true else false
end

local function initTopBarButtons(self: Window)
    local close = self:CreateTopBarButton("Close", closeIcon, function()
        self:Hide()
    end)
    close.Instance.LayoutOrder = 3

	local maximize = self:CreateTopBarButton("Maximize", maximizeIcon, function()
		maximizeToggle(self)
	end)
    maximize.Instance.LayoutOrder = 2

	local restore = self:CreateTopBarButton("Restore", restoreIcon, function()
		maximizeToggle(self, true)
	end)
    restore.Instance.Visible = false
    restore.Instance.LayoutOrder = 2

    local minimize = self:CreateTopBarButton("Minimize", minimizeIcon, function()
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
    Title = "Window",
    Position = UDim2.new(0.5, 0, 0.5, 0),
    Size = UDim2.new(0, 640, 0, 480),
    Draggable = true,
    Resizable = true
}

function Window.new(options: WindowOptions): Window
    options = TableUtils.Merge(DefaultOptions, options)

    local self: Window = setmetatable({}, Window) :: Window

    local instance = BaseBlueprint:Build() :: instance
    local topBar = instance.TopBar
    local icon = topBar.Icon
    local buttons = topBar.Buttons
    local listLayout = buttons.UIListLayout

    self.Class = "Window"
    self.Instance = instance
    self.TopBarButtons = {}

    ThemeService.Link(instance, "Background", {"BackgroundColor3"})
    ThemeService.Link(topBar.Title, "PrimaryText", {"TextColor3"})
    ThemeService.Link(icon, "Highlight", {"ImageColor3"})

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

    listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateThisTopBar)
    topBar:GetPropertyChangedSignal("Size"):Connect(updateThisTopBar)
    icon:GetPropertyChangedSignal("Visible"):Connect(updateThisTopBar)
    
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
    
    self.Instance.Name = options.Title :: string
    self.Instance.Parent = Registry.Settings.ScreenGui

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
    else
        topBarIcon.Visible = false
    end
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

function Window.CreateTopBarButton(self: Window, name: string, icon: Icon.Icon, callback: () -> ()): IconButton.IconButton
    local button = IconButton.new(icon, callback)
    button.Instance.Parent = self.Instance.TopBar.Buttons

    self.TopBarButtons[name] = button

    return button
end

function Window.Show(self: Window)
    local instance = self.Instance

    instance.Visible = true

    local tweenInfo = Tweener.TweenInfo(0.25, Enum.EasingStyle.Cubic)

    local windowT = Tweener.Tween(instance, tweenInfo, "hide_show", {
        GroupTransparency = 0
    }, false)
    local uiScaleT = Tweener.Tween(instance.UIScale, tweenInfo, "hide_show", {
        Scale = 1
    }, false)

    windowT:Play()
    uiScaleT:Play()
end

function Window.Hide(self: Window)
    local instance = self.Instance
    local tweenInfo = Tweener.TweenInfo(0.25, Enum.EasingStyle.Cubic)

    local windowT = Tweener.Tween(instance, tweenInfo, "hide_show", {
        GroupTransparency = 1
    }, false)
    local uiScaleT = Tweener.Tween(instance.UIScale, tweenInfo, "hide_show", {
        Scale = 0.85
    }, false)

    windowT:Play()
    uiScaleT:Play()

    task.wait(0.25)

    instance.Visible = false
end

function Window.Destroy(self: Window)
    self.ResizeController:Destroy()
    self.DragController:Destroy()

    for _, button in self.TopBarButtons do
        button:Destroy()
    end

    setmetatable(self :: any, nil)
    table.clear(self :: any)
end

return Window