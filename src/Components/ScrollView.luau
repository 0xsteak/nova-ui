local Blueprint = require("../Modules/Blueprint")
local ThemeService = require("../Modules/ThemeService")
local Tweener = require("../Modules/Tweener")
local Signal = require("../Modules/Signal")
local TableUtils = require("../Utils/TableUtils")

-- -- -- -- --

type ScrollViewImpl = {
    __index: ScrollViewImpl,
    new: () -> ScrollView,
    SetScrollingDirection: (self: ScrollView, direction: Enum.ScrollingDirection) -> (),
    SetScrollingEnabled: (self: ScrollView, enabled: boolean) -> (),
    SetScrollBarThickness: (self: ScrollView, thickness: number) -> (),
    Destroy: (self: ScrollView) -> ()
}

type instance = Frame & {
    View: ScrollingFrame,
    VerticalScrollBar: Frame & {
        Thumb: Frame
    },
    HorizontalScrollBar: Frame & {
        Thumb: Frame
    }
}

type self = {
    Class: "ScrollView",
    Instance: instance,
    Connections: {RBXScriptConnection},
    ScrollingDirection: Enum.ScrollingDirection,
    ScrollingEnabled: boolean,
    ScrollBarThickness: number
}

type ScrollViewOptions = {
    ScrollingDirection: Enum.ScrollingDirection?,
    ScrollingEnabled: boolean?,
    ScrollBarThickness: number?
}

export type ScrollView = typeof(setmetatable({} :: self, {} :: ScrollViewImpl))

-- -- -- -- --

local ScrollView = {}
ScrollView.__index = ScrollView

local UserInputService = game:GetService("UserInputService")

local BaseBlueprint: Blueprint.Blueprint = Blueprint.new({
    Class = "Frame",
    Name = "ScrollView",
    Active = true,
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    {
        Class = "ScrollingFrame",
        Name = "View",
        Active = true,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 1, 0),
        CanvasSize = UDim2.new(),
        ScrollBarThickness = 0,
    },
    {
        Class = "Frame",
        Name = "VerticalScrollBar",
        Active = true,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        {
            Class = "UICorner",
            CornerRadius = UDim.new(1, 0)
        },
        {
            Class = "Frame",
            Name = "Thumb",
            Active = true,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 0),
            {
                Class = "UICorner",
                CornerRadius = UDim.new(1, 0)
            }
        }
    },
    {
        Class = "Frame",
        Name = "HorizontalScrollBar",
        Active = true,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        {
            Class = "UICorner",
            CornerRadius = UDim.new(1, 0)
        },
        {
            Class = "Frame",
            Name = "Thumb",
            Active = true,
            BackgroundTransparency = 1,
            Size = UDim2.new(0, 0, 1, 0),
            {
                Class = "UICorner",
                CornerRadius = UDim.new(1, 0)
            }
        }
    }
})

local function updateVerticalScrollBar(self: ScrollView)
    local instance = self.Instance
    local view = instance.View
    local scrollBar = instance.VerticalScrollBar
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
    local instance = self.Instance
    local view = instance.View
    local scrollBar = instance.HorizontalScrollBar
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
    ScrollBarThickness = 4
}

function ScrollView.new(options: ScrollViewOptions): ScrollView
    options = TableUtils.Merge(DefaultOptions, options)

    local self = setmetatable({}, ScrollView) :: ScrollView

    local instance = BaseBlueprint:Build() :: instance
    local view = instance.View
    local verticalSB = instance.VerticalScrollBar
    local verticalSBThumb = verticalSB.Thumb
    local horizontalSB = instance.HorizontalScrollBar
    local horizontalSBThumb = horizontalSB.Thumb

    self.Instance = instance
    self.Connections = {}

    self:SetScrollingDirection(options.ScrollingDirection)
    self:SetScrollingEnabled(options.ScrollingEnabled)
    self:SetScrollBarThickness(options.ScrollBarThickness)

    ThemeService.Link(verticalSB, "ScrollBarTrack", {"BackgroundColor3"})
    ThemeService.Link(verticalSBThumb, "ScrollBarThumb", {"BackgroundColor3"})
    ThemeService.Link(horizontalSB, "ScrollBarTrack", {"BackgroundColor3"})
    ThemeService.Link(horizontalSBThumb, "ScrollBarThumb", {"BackgroundColor3"})

    ThemeService.Update()

    local VerticalSBDragEnd = Signal.new()
    local HorizontalSBDragEnd = Signal.new()

    local autoUpdateLocked = false
    local dragging = false
    local dragDirection: "X" | "Y"
    local startPos: Vector2
    local startMousePos: Vector3
    local isMouseOnVerticalThumb = false
    local isMouseOnHorizontalThumb = false

    local function updateVerticalSBInput(mousePos: Vector3)
        if self.ScrollingDirection == Enum.ScrollingDirection.X then return end

        local newValue = math.clamp(startPos.Y - verticalSB.AbsolutePosition.Y + mousePos.Y - startMousePos.Y, 0, verticalSB.AbsoluteSize.Y - verticalSBThumb.AbsoluteSize.Y)
        verticalSBThumb.Position = UDim2.new(0, 0, 0, newValue)
        view.CanvasPosition = Vector2.new(view.CanvasPosition.X, newValue / (verticalSB.AbsoluteSize.Y - verticalSBThumb.AbsoluteSize.Y) * (view.AbsoluteCanvasSize.Y - view.AbsoluteWindowSize.Y))
    end

    local function updateHorizontalSBInput(mousePos: Vector3)
        if self.ScrollingDirection == Enum.ScrollingDirection.Y then return end

        local newValue = math.clamp(startPos.X - horizontalSB.AbsolutePosition.X + mousePos.X - startMousePos.X, 0, horizontalSB.AbsoluteSize.X - horizontalSBThumb.AbsoluteSize.X)
        horizontalSBThumb.Position = UDim2.new(0, newValue, 0, 0)
		view.CanvasPosition = Vector2.new(newValue / (horizontalSB.AbsoluteSize.X - horizontalSBThumb.AbsoluteSize.X) * (view.AbsoluteCanvasSize.X - view.AbsoluteWindowSize.X), view.CanvasPosition.Y)
    end

    local tweenInfo = Tweener.TweenInfo(0.25)
    local verticalHideThread: thread
    local horizontalHideThread: thread

    local function showVerticalSB()
        if verticalHideThread then
            task.cancel(verticalHideThread)
        end

        local t1 = Tweener.Tween(verticalSB, tweenInfo, "hide_show", {
            BackgroundTransparency = 0.75
        })
        local t2 = Tweener.Tween(verticalSBThumb, tweenInfo, "hide_show", {
            BackgroundTransparency = 0.75
        })

        t1:Play()
        t2:Play()
    end

    local function _hideVerticalSBFunc()
        local t1 = Tweener.Tween(verticalSB, tweenInfo, "hide_show", {
            BackgroundTransparency = 1
        })
        local t2 = Tweener.Tween(verticalSBThumb, tweenInfo, "hide_show", {
            BackgroundTransparency = 1
        })

        t1:Play()
        t2:Play()
    end

    local function hideVerticalSB()
        verticalHideThread = task.delay(1, _hideVerticalSBFunc)
    end

    local function showHorizontalSB()
        if horizontalHideThread then
            task.cancel(horizontalHideThread)
        end

        local t1 = Tweener.Tween(horizontalSB, tweenInfo, "hide_show", {
            BackgroundTransparency = 0.75
        })
        local t2 = Tweener.Tween(horizontalSBThumb, tweenInfo, "hide_show", {
            BackgroundTransparency = 0.75
        })

        t1:Play()
        t2:Play()
    end

    local function _hideHorizontalSBFunc()
        local t1 = Tweener.Tween(horizontalSB, tweenInfo, "hide_show", {
            BackgroundTransparency = 1
        })
        local t2 = Tweener.Tween(horizontalSBThumb, tweenInfo, "hide_show", {
            BackgroundTransparency = 1
        })

        t1:Play()
        t2:Play()
    end

    local function hideHorizontalSB()
        horizontalHideThread = task.delay(1, _hideHorizontalSBFunc)
    end

    local function updateTheseScrollBars()
        if autoUpdateLocked then return end
        updateVerticalScrollBar(self)
        updateHorizontalScrollBar(self)

        if verticalSB.BackgroundTransparency ~= 0.75 then
            showVerticalSB()
            hideVerticalSB()
        end

        if horizontalSB.BackgroundTransparency ~= 0.75 then
            showHorizontalSB()
            hideHorizontalSB()
        end
    end

    view:GetPropertyChangedSignal("CanvasPosition"):Connect(updateTheseScrollBars)
    view:GetPropertyChangedSignal("AbsoluteCanvasSize"):Connect(updateTheseScrollBars)

    verticalSB.MouseEnter:Connect(function()
        showVerticalSB()
    end)

    verticalSB.MouseLeave:Connect(function()
        if dragging and dragDirection == "Y" then
            VerticalSBDragEnd:Wait()
        end

        hideVerticalSB()
    end)

    verticalSBThumb.MouseEnter:Connect(function()
        isMouseOnVerticalThumb = true
    end)

    verticalSBThumb.MouseLeave:Connect(function()
        isMouseOnVerticalThumb = false
    end)

    verticalSB.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 and not isMouseOnVerticalThumb then
            verticalSBThumb.Position = UDim2.new(0, 0, 0, input.Position.Y - verticalSB.AbsolutePosition.Y - (verticalSBThumb.AbsoluteSize.Y * 0.5))
            
            dragging = true
            dragDirection = "Y"
            startPos = verticalSBThumb.AbsolutePosition
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
                    VerticalSBDragEnd:Fire()
                end
            end)
            
            updateVerticalSBInput(input.Position)
        end
    end)

    verticalSBThumb.InputBegan:Connect(function(input: InputObject)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragDirection = "Y"
            startPos = verticalSBThumb.AbsolutePosition
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
                    VerticalSBDragEnd:Fire()
                end
            end)
        end
    end)

    horizontalSB.MouseEnter:Connect(function()
        showHorizontalSB()
    end)

    horizontalSB.MouseLeave:Connect(function()
        if dragging and dragDirection == "X" then
            HorizontalSBDragEnd:Wait()
        end

        hideHorizontalSB()
    end)

    horizontalSBThumb.MouseEnter:Connect(function()
        isMouseOnHorizontalThumb = true
    end)

    horizontalSBThumb.MouseLeave:Connect(function()
        isMouseOnHorizontalThumb = false
    end)

    horizontalSB.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 and not isMouseOnHorizontalThumb then
            horizontalSBThumb.Position = UDim2.new(0, input.Position.X - horizontalSB.AbsolutePosition.X - (horizontalSBThumb.AbsoluteSize.X * 0.5), 0, 0)
            
            dragging = true
            dragDirection = "X"
            startPos = horizontalSBThumb.AbsolutePosition
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
                    HorizontalSBDragEnd:Fire()
                end
            end)
            
            updateHorizontalSBInput(input.Position)
        end
    end)

    horizontalSBThumb.InputBegan:Connect(function(input: InputObject)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragDirection = "X"
            startPos = horizontalSBThumb.AbsolutePosition
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
                    HorizontalSBDragEnd:Fire()
                end
            end)
        end
    end)

    self.Connections[1] = UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement and dragging then
            if dragDirection == "Y" then
                updateVerticalSBInput(input.Position)
            else
                updateHorizontalSBInput(input.Position)
            end
        end
    end)

    updateTheseScrollBars()

    return self
end

function ScrollView.SetScrollingDirection(self: ScrollView, direction: Enum.ScrollingDirection)
    self.ScrollingDirection = direction
    self.Instance.View.ScrollingDirection = direction
end

function ScrollView.SetScrollingEnabled(self: ScrollView, enabled: boolean)
    self.ScrollingEnabled = enabled
    self.Instance.View.ScrollingEnabled = enabled
end

function ScrollView.SetScrollBarThickness(self: ScrollView, thickness: number)
    self.ScrollBarThickness = thickness

    local verticalSB = self.Instance.VerticalScrollBar
    local horizontalSB = self.Instance.HorizontalScrollBar

    verticalSB.Position = UDim2.new(1, -thickness - 5, 0, 10)
    verticalSB.Size = UDim2.new(0, thickness, 1, -20)
    horizontalSB.Position = UDim2.new(0, 10, 1, -thickness - 5)
    horizontalSB.Size = UDim2.new(1, -25, 0, thickness)
end

function ScrollView.Destroy(self: ScrollView)
    for _, connection in self.Connections do
        connection:Disconnect()
    end

    setmetatable(self :: any, nil)
    table.clear(self :: any)
end

return ScrollView