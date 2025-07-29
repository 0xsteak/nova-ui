local Icon = require("../Classes/Icon")
local Blueprint = require("../Modules/Blueprint")
local ThemeService = require("../Modules/ThemeService")
local Tweener = require("../Modules/Tweener")

-- -- -- -- --

type IconButtonImpl = {
    __index: IconButtonImpl,
    new: (icon: Icon.Icon, callback: () -> ()) -> IconButton,
    Disable: (self: IconButton) -> (),
    Enable: (self: IconButton) -> (),
    Destroy: (self: IconButton) -> ()
}

export type IconButton = typeof(setmetatable({} :: self, {} :: IconButtonImpl))

type self = {
    Class: "IconButton",
    Instance: instance,
    Callback: () -> (),
    Enabled: boolean
}

type instance = CanvasGroup & {
    Button: TextButton & {
        UICorner: UICorner,
        Icon: ImageLabel
    }
}

-- -- -- -- --

local IconButton = {} :: IconButtonImpl
IconButton.__index = IconButton

local BaseBlueprint: Blueprint.Blueprint = Blueprint.new({
    Class = "CanvasGroup",
    Size = UDim2.new(0, 25, 0, 25),
    Visible = false,
    {
        Class = "UICorner",
        CornerRadius = UDim.new(0, 8)
    },
    {
        Class = "TextButton",
        Name = "Button",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Text = "",
        {
            Class = "ImageLabel",
            Name = "Icon",
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
            Position = UDim2.new(0.5, 0, 0.5, 0),
            Size = UDim2.new(0, 16, 0, 16)
        },
    }
})

function IconButton.new(icon: Icon.Icon, callback: () -> ()): IconButton
    local self = setmetatable({}, IconButton) :: IconButton
    self.Class = "IconButton"
    self.Callback = callback or function() end
    self.Enabled = true

    local instance = BaseBlueprint:Build() :: instance
    local Button = instance.Button
    local buttonIcon = Button.Icon

    icon:ApplyTo(buttonIcon)

    ThemeService.Link(instance, "Background", {"BackgroundColor3"})
    ThemeService.Link(buttonIcon, "SecondaryIcon", {"ImageColor3"})

    ThemeService.Update()

    local isMouseDown = false
    local isMouseOnObject = false
    local tweenInfo = Tweener.TweenInfo(0.25)

    local function onMouseEnter()
        isMouseOnObject = true
        if not isMouseDown then
            Tweener.Tween(instance, tweenInfo, "hover", {
                BackgroundColor3 = ThemeService.GetColor("IconButtonHover")
            })
            Tweener.Tween(buttonIcon, tweenInfo, "hover", {
                ImageColor3 = ThemeService.GetColor("PrimaryIcon")
            })
        end
    end

    local function onMouseLeave()
        isMouseOnObject = false
        if not isMouseDown then
            Tweener.Tween(instance, tweenInfo, "default", {
                BackgroundColor3 = ThemeService.GetColor("Background")
            })
            Tweener.Tween(buttonIcon, tweenInfo, "default", {
                ImageColor3 = ThemeService.GetColor("SecondaryIcon")
            })
        end
    end

    local function onMouseUp()
        isMouseDown = false
        if isMouseOnObject then
            onMouseEnter()
        else
            onMouseLeave()
        end
    end

    Button.InputBegan:Connect(function(input: InputObject)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            isMouseDown = true
            Tweener.Tween(instance, tweenInfo, "down", {
                BackgroundColor3 = ThemeService.GetColor("IconButtonDown")
            })

            local connection: RBXScriptConnection
            connection = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    onMouseUp()
                    connection:Disconnect()
                end
            end)
        end
    end)

    Button.MouseButton1Click:Connect(function()
        self.Callback()
    end)

    Button.MouseEnter:Connect(onMouseEnter)
    Button.MouseLeave:Connect(onMouseLeave)

    instance.Visible = true

    self.Instance = instance

    return self
end

function IconButton.Disable(self: IconButton)
    self.Enabled = false

    local instance = self.Instance

    instance.GroupTransparency = 0.5
    instance.Interactable = false
end

function IconButton.Enable(self: IconButton)
    self.Enabled = true

    local instance = self.Instance

    instance.GroupTransparency = 0
    instance.Interactable = true
end

function IconButton.Destroy(self: IconButton)
    self.Instance:Destroy()

    setmetatable(self :: any, nil)
    table.clear(self :: any)
end

return IconButton