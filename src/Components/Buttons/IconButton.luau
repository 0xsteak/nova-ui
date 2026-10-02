local Button = require(script.Parent.Button)
local Blueprint = require(script.Parent.Parent.Parent.Classes.Blueprint)
local Icon = require(script.Parent.Parent.Parent.Classes.Icon)
local GuiInputService = require(script.Parent.Parent.Parent.Services.GuiInputService)
local ThemeService = require(script.Parent.Parent.Parent.Services.ThemeService)
local TransitionService = require(script.Parent.Parent.Parent.Services.TransitionService)
local Transition = require(script.Parent.Parent.Parent.Services.TransitionService.Transition)
local TransitionGroup = require(script.Parent.Parent.Parent.Services.TransitionService.TransitionGroup)

type IconButtonProps = {
	ClassName: 'NovaUI.IconButton',
	Instance: instance,
	Button: Button.Button,
	TransitionGroups: {
		Idle: TransitionGroup.TransitionGroup,
		Hover: TransitionGroup.TransitionGroup,
		MouseDown: TransitionGroup.TransitionGroup,
	},
	State: State,
}

type instance = ImageButton & {
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

local _basePreset = {
	Time = 0.25,
	EasingStyle = Enum.EasingStyle.Quad,
	EasingDirection = Enum.EasingDirection.Out,
}

local IdlePreset: TransitionGroup.Preset = {
	_base = _basePreset,
	Button = {
		PropertyTable = {
			BackgroundTransparency = 1,
		} :: Transition.PropertyTable<CanvasGroup>,
	},
	Icon = {
		PropertyTable = function()
			return {
				ImageTransparency = 0.25,
			} :: Transition.PropertyTable<ImageLabel>
		end,
	},
}

local HoverPreset: TransitionGroup.Preset = {
	_base = _basePreset,
	Button = {
		PropertyTable = {
			BackgroundTransparency = 0.8,
		} :: Transition.PropertyTable<CanvasGroup>,
	},
	Icon = {
		PropertyTable = function()
			return {
				ImageTransparency = 0,
			} :: Transition.PropertyTable<ImageLabel>
		end,
	},
}

local MouseDownPreset: TransitionGroup.Preset = {
	_base = _basePreset,
	Button = {
		PropertyTable = {
			BackgroundTransparency = 0.9,
		} :: Transition.PropertyTable<CanvasGroup>,
	},
}

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

	local transitionGroups = self.TransitionGroups
	local idleTransition = transitionGroups.Idle
	local hoverTransition = transitionGroups.Hover
	local mouseDownTransition = transitionGroups.MouseDown

	-- leave
	if oldState == 'Idle' then
		idleTransition:ApplyAll()
	elseif oldState == 'Hover' then
		hoverTransition:ApplyAll()
	elseif oldState == 'MouseDown' then
		mouseDownTransition:ApplyAll()
	end

	self.State = newState

	-- enter
	if newState == 'Idle' then
		idleTransition:ReplayAll()
	elseif newState == 'Hover' then
		hoverTransition:ReplayAll()
	elseif newState == 'MouseDown' then
		mouseDownTransition:ReplayAll()
	elseif newState == 'Disabled' then
		self.Instance.Icon.ImageTransparency = 0.5
	end
end

function IconButton.new(icon: Icon.Icon, callback: (() -> ())?, buttonSize: UDim2?, iconSize: UDim2?): IconButton
	local self: IconButton = setmetatable({}, IconButton)
	self.Enabled = true

	local button = Button.new(callback)
	self.Button = button
	self.Instance = button.Instance

	local folder = BaseBlueprint:Build()
	local instance = button.Instance :: instance

	for _, child in folder:GetChildren() do
		child.Parent = instance
	end
	folder:Destroy()

	local buttonIcon = instance.Icon

	instance.Size = buttonSize or UDim2.new(0, 25, 0, 25)
	buttonIcon.Size = iconSize or UDim2.new(0, 16, 0, 16)

	local idleTransition = TransitionService.CreateGroup(
		{ Button = instance, Icon = buttonIcon },
		IdlePreset,
		{ 'Theme' }
	)
	local hoverTransition = TransitionService.CreateGroup(
		{ Button = instance, Icon = buttonIcon },
		HoverPreset,
		{ 'Theme' }
	)
	local mouseDownTransition = TransitionService.CreateGroup({ Button = instance }, MouseDownPreset, { 'Theme' })

	self.TransitionGroups = {
		Idle = idleTransition,
		Hover = hoverTransition,
		MouseDown = mouseDownTransition,
	}

	icon:ApplyTo(buttonIcon)

	GuiInputService.SetOptions(instance, {
		RequireOnTop = {
			IgnoreDescendants = true,
		},
	})
	local inputBegan = GuiInputService.AddEvent(instance, 'InputBegan')
	local mouseEnter = GuiInputService.AddEvent(instance, 'MouseEnter')
	local mouseLeave = GuiInputService.AddEvent(instance, 'MouseLeave')

	ThemeService.Bind(instance, 'Foreground', 'BackgroundColor3')
	ThemeService.Bind(buttonIcon, 'Foreground', 'ImageColor3')

	ThemeService.Update()

	self.State = 'Idle'
	idleTransition:ApplyAll()

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

	instance.Visible = true

	self.Instance = instance

	return self
end

function IconButton.Disable(self: IconButton)
	self.Button:Disable()
	self.Enabled = false
end

function IconButton.Enable(self: IconButton)
	self.Enabled = true

	local instance = self.Instance

	instance.GroupTransparency = 0
	instance.Interactable = true
end

function IconButton.SetParent(self: IconButton, parent: Instance)
	self.Instance.Parent = parent
end

function IconButton.Destroy(self: IconButton)
	self.Button:Destroy()
end

return IconButton
