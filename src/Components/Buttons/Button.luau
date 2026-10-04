local Blueprint = require(script.Parent.Parent.Parent.Classes.Blueprint)
local GuiInputService = require(script.Parent.Parent.Parent.Services.GuiInputService)

type ButtonProps = {
	Base: ImageButton,
	Callback: () -> (),
	Enabled: boolean,
}

local Button = {}
Button.__index = Button

Button.ClassName = 'NovaUI.Button'

export type Button = typeof(setmetatable({} :: ButtonProps, Button))

local BaseBlueprint = Blueprint.new({
	ClassName = 'ImageButton',
	AutoButtonColor = false,
	BackgroundTransparency = 1,
	ImageTransparency = 1,
} :: Blueprint.BlueprintData<ImageButton>)

function Button.__tostring(self: Button)
	return Button.ClassName
end

function Button.new(callback: (() -> ())?): Button
	local self: Button = setmetatable({}, Button)

	local base = BaseBlueprint:Build()

	self.Base = base
	self.Callback = callback or function() end
	self.Enabled = true

	GuiInputService.Register(base, {
		RequireOnTop = true,
	})
	local mb1Click = GuiInputService.AddEvent(base, 'MouseButton1Click')

	mb1Click:Connect(function()
		if self.Enabled then
			self.Callback()
		end
	end)

	return self
end

function Button.Disable(self: Button)
	self.Enabled = false
	self.Base.Interactable = false
end

function Button.Enable(self: Button)
	self.Enabled = true
	self.Base.Interactable = true
end

function Button.SetSize(self: Button, size: UDim2)
	self.Base.Size = size
end

function Button.SetPosition(self: Button, position: UDim2)
	self.Base.Position = position
end

function Button.SetParent(self: Button, parent: Instance)
	self.Base.Parent = parent
end

function Button.Destroy(self: Button)
	self.Base:Destroy()
end

return Button
