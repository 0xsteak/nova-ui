local Button = require(script.Parent.Button)
local Blueprint = require(script.Parent.Parent.Parent.Classes.Blueprint)
local Icon = require(script.Parent.Parent.Parent.Classes.Icon)
local GuiInputService = require(script.Parent.Parent.Parent.Services.GuiInputService)
local ThemeService = require(script.Parent.Parent.Parent.Services.ThemeService)
local Transition = require(script.Parent.Parent.Parent.Services.TransitionService.Transition)

type IconButtonProps = {
	ClassName: 'NovaUI.IconButton',
	Base: base,
	Button: Button.Button,
	Transitions: {
		Idle: Transition.Transition,
		Hover: Transition.Transition,
		MouseDown: Transition.Transition,
	},
	State: State,
}

type base = ImageButton & {
	UICorner: UICorner,
	Icon: ImageLabel,
}

type State = 'Idle' | 'Hover' | 'MouseDown' | 'Disabled'

local IconButton = {}
IconButton.__index = IconButton

IconButton.ClassName = 'NovaUI.IconButton'

export type IconButton = typeof(setmetatable({} :: IconButtonProps, IconButton))

function IconButton.__tostring(self: IconButton)
	return IconButton.ClassName
end

local TWEEN_INFO = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local BaseBlueprint = Blueprint.new({
	ClassName = 'Folder',
	{
		ClassName = 'UICorner',
		CornerRadius = UDim.new(0, 8),
	},
	{
		ClassName = 'ImageLabel',
		Name = 'Icon',
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(0, 16, 0, 16),
		ImageColor3 = Color3.new(1, 1, 1),
	},
})

local function setState(self: IconButton, newState: State)
	if not self.Button.Enabled and newState ~= 'Disabled' then
		return
	end

	local oldState = self.State

	local transitions = self.Transitions
	local idleTransition = transitions.Idle
	local hoverTransition = transitions.Hover
	local mouseDownTransition = transitions.MouseDown

	-- leave
	if oldState == 'Idle' then
		idleTransition:Apply()
	elseif oldState == 'Hover' then
		hoverTransition:Apply()
	elseif oldState == 'MouseDown' then
		mouseDownTransition:Apply()
	end

	self.State = newState

	-- enter
	if newState == 'Idle' then
		idleTransition:Play()
	elseif newState == 'Hover' then
		hoverTransition:Play()
	elseif newState == 'MouseDown' then
		mouseDownTransition:Play()
	elseif newState == 'Disabled' then
		self.Base.Icon.ImageTransparency = 0.5
	end
end

function IconButton.new(icon: Icon.Icon, callback: (() -> ())?, buttonSize: UDim2?, iconSize: UDim2?): IconButton
	local self: IconButton = setmetatable({}, IconButton)
	self.Enabled = true

	local button = Button.new(callback)
	self.Button = button
	self.Base = button.Base

	local folder = BaseBlueprint:Build()
	local base = button.Base :: base

	for _, child in folder:GetChildren() do
		child.Parent = base
	end
	folder:Destroy()

	local buttonIcon = base.Icon

	base.Size = buttonSize or UDim2.new(0, 25, 0, 25)
	buttonIcon.Size = iconSize or UDim2.new(0, 16, 0, 16)

	local idleTransition = Transition.new({
		[base] = {
			BackgroundTransparency = 1,
		},
		[buttonIcon] = {
			ImageTransparency = 0.25,
		},
	}, TWEEN_INFO)
	local hoverTransition = Transition.new({
		[base] = {
			BackgroundTransparency = 0.8,
		},
		[buttonIcon] = {
			ImageTransparency = 0,
		},
	}, TWEEN_INFO)
	local mouseDownTransition = Transition.new({
		[base] = {
			BackgroundTransparency = 0.9,
		},
	}, TWEEN_INFO)

	self.Transitions = {
		Idle = idleTransition,
		Hover = hoverTransition,
		MouseDown = mouseDownTransition,
	}

	icon:ApplyTo(buttonIcon)

	GuiInputService.SetOptions(base, {
		RequireOnTop = {
			IgnoreDescendants = true,
		},
	})
	local inputBegan = GuiInputService.AddEvent(base, 'InputBegan')
	local mouseEnter = GuiInputService.AddEvent(base, 'MouseEnter')
	local mouseLeave = GuiInputService.AddEvent(base, 'MouseLeave')

	ThemeService.Bind(base, 'Foreground', 'BackgroundColor3')
	ThemeService.Bind(buttonIcon, 'Foreground', 'ImageColor3')

	ThemeService.Update()

	self.State = 'Idle'
	idleTransition:Apply()

	local isMouseDown = false
	local isMouseOnObject = false

	local function onMouseEnter()
		isMouseOnObject = true
		if not isMouseDown then
			setState(self, 'Hover')
		end
	end

	local function onMouseLeave()
		isMouseOnObject = false
		if not isMouseDown then
			setState(self, 'Idle')
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

	inputBegan:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			isMouseDown = true
			setState(self, 'MouseDown')

			local connection: RBXScriptConnection
			connection = input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					onMouseUp()
					connection:Disconnect()
				end
			end)
		end
	end)
	mouseEnter:Connect(onMouseEnter)
	mouseLeave:Connect(onMouseLeave)

	base.Visible = true

	self.Base = base

	return self
end

function IconButton.Disable(self: IconButton)
	self.Button:Disable()
	self.Enabled = false
end

function IconButton.Enable(self: IconButton)
	self.Enabled = true

	local base = self.Base

	base.GroupTransparency = 0
	base.Interactable = true
end

function IconButton.SetParent(self: IconButton, parent: Instance)
	self.Base.Parent = parent
end

function IconButton.Destroy(self: IconButton)
	self.Button:Destroy()
end

return IconButton
