local Blueprint = require(script.Parent.Parent.Parent.Classes.Blueprint)
local GuiInputService = require(script.Parent.Parent.Parent.Services.GuiInputService)

type ButtonProps = {
	ClassName: 'NovaUI.Button',
	Instance: ImageButton,
	Callback: () -> (),
	Enabled: boolean,
}

local Button = {}
Button.__index = Button

export type Button = typeof(setmetatable({} :: ButtonProps, Button))

local BaseBlueprint = Blueprint.new({
	ClassName = 'ImageButton',
	AutoButtonColor = false,
	BackgroundTransparency = 1,
	ImageTransparency = 1,
} :: Blueprint.BlueprintData<ImageButton>)

function Button.__tostring(self: Button)
	return self.ClassName
end

function Button.new(callback: (() -> ())?): Button
	local self: Button = setmetatable({}, Button)

	local instance = BaseBlueprint:Build()

	self.ClassName = 'NovaUI.Button'
	self.Instance = instance
	self.Callback = callback or function() end
	self.Enabled = true

	GuiInputService.Register(instance, {
		RequireOnTop = true,
	})
	local mb1Click = GuiInputService.AddEvent(instance, 'MouseButton1Click')

	mb1Click:Connect(function()
		if self.Enabled then
			self.Callback()
		end
	end)

	return self
end

function Button.Disable(self: Button)
	self.Enabled = false
	self.Instance.Interactable = false
end

function Button.Enable(self: Button)
	self.Enabled = true
	self.Instance.Interactable = true
end

function Button.SetSize(self: Button, size: UDim2)
	self.Instance.Size = size
end

function Button.SetPosition(self: Button, position: UDim2)
	self.Instance.Position = position
end

function Button.SetParent(self: Button, parent: Instance)
	self.Instance.Parent = parent
end

function Button.Destroy(self: Button)
	self.Instance:Destroy()
end

return Button
