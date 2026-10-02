local TableUtils = require(script.Parent.Parent.Utils.TableUtils)
local Blueprint = require(script.Parent.Parent.Classes.Blueprint)
local ThemeService = require(script.Parent.Parent.Services.ThemeService)
local Preferences = require(script.Parent.Parent.Registry.Preferences)
local TextService = game:GetService('TextService')
local Signal = require(script.Parent.Parent.Packages.Signal)

type DisplayMode = 'Fixed' | 'AutoHeight'

type LabelProps = {
	Instance: TextLabel,
	Params: GetTextBoundsParams,
	DisplayMode: DisplayMode,
	Connections: { Signal.Connection },
	_updateThreadId: number,
}

type LabelOptions = {
	Text: string?,
	TextXAlignment: Enum.TextXAlignment?,
	TextYAlignment: Enum.TextYAlignment?,
	TextSize: number?,
	TextTruncate: Enum.TextTruncate?,
	TextWrapped: boolean?,
	Size: UDim2?,
	DisplayMode: DisplayMode?,
}

local Label = {}
Label.__index = Label

Label.ClassName = 'NovaUI.Label'

export type Label = typeof(setmetatable({} :: LabelProps, Label))

function Label.__tostring(self: Label)
	return Label.ClassName
end

local BaseBlueprint = Blueprint.new({
	ClassName = 'TextLabel',
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	FontFace = Font.new(Preferences.GetFontFamily()),
})

local function updateHeight(self: Label)
	if self.DisplayMode == 'Fixed' then
		return
	end

	local instance: TextLabel = self.Instance
	local params = self.Params
	local width = instance.AbsoluteSize.X

	params.Text = instance.Text
	params.Width = width
	params.Size = instance.TextSize
	params.Font = instance.FontFace

	local currentThreadId = self._updateThreadId + 1
	self._updateThreadId = currentThreadId

	local height = TextService:GetTextBoundsAsync(params).Y

	if self._updateThreadId ~= currentThreadId then
		return
	end

	instance.Size = UDim2.new(instance.Size.X.Scale, instance.Size.X.Offset, 0, height)
end

local DefaultOptions = {
	Text = 'Label',
	TextXAlignment = Enum.TextXAlignment.Center,
	TextYAlignment = Enum.TextYAlignment.Center,
	TextSize = 14,
	TextTruncate = Enum.TextTruncate.None,
	TextWrapped = false,
	Size = UDim2.new(0, 100, 0, 100),
	DisplayMode = 'Fixed',
} :: LabelOptions

function Label.new(options: LabelOptions?): Label
	options = TableUtils.Merge(DefaultOptions, options)

	local self: Label = setmetatable({}, Label)

	local instance = BaseBlueprint:Build() :: TextLabel

	self.Instance = instance
	self.DisplayMode = options.DisplayMode
	self._updateThreadId = 0

	local connections = {}

	local params = Instance.new('GetTextBoundsParams')
	self.Params = params

	local function updateThisHeight()
		updateHeight(self)
	end

	local lastWidth = instance.AbsoluteSize.X
	instance:GetPropertyChangedSignal('AbsoluteSize'):Connect(function()
		local width = instance.AbsoluteSize.X
		if width ~= lastWidth then
			updateThisHeight()
			lastWidth = width
		end
	end)
	instance:GetPropertyChangedSignal('Text'):Connect(updateThisHeight)
	instance:GetPropertyChangedSignal('TextSize'):Connect(updateThisHeight)
	instance:GetPropertyChangedSignal('FontFace'):Connect(updateThisHeight)

	ThemeService.Bind(instance, 'PrimaryText', 'TextColor3')
	ThemeService.Update()

	self:SetText(options.Text)
	self:SetXAlignment(options.TextXAlignment)
	self:SetYAlignment(options.TextYAlignment)
	self:SetTextSize(options.TextSize)
	self:SetTextTruncate(options.TextTruncate)
	self:SetTextWrapped(options.DisplayMode == 'AutoHeight' and true or options.TextWrapped)
	self:SetSize(options.Size)

	connections[1] = Preferences.FontFamilyChanged:Connect(function(newFamily: string)
		local font = instance.FontFace
		font.Family = newFamily

		instance.FontFace = font
	end)

	self.Connections = connections

	return self
end

function Label.SetText(self: Label, text: string)
	self.Instance.Text = text
end

function Label.SetXAlignment(self: Label, alignment: Enum.TextXAlignment)
	self.Instance.TextXAlignment = alignment
end

function Label.SetYAlignment(self: Label, alignment: Enum.TextYAlignment)
	self.Instance.TextYAlignment = alignment
end

function Label.SetTextSize(self: Label, size: number)
	self.Instance.TextSize = size
end

function Label.SetTextTruncate(self: Label, value: Enum.TextTruncate)
	self.Instance.TextTruncate = value
end

function Label.SetTextWrapped(self: Label, wrapped: boolean)
	self.Instance.TextWrapped = wrapped
end

function Label.SetFontWeight(self: Label, weight: Enum.FontWeight)
	local instance = self.Instance

	local font = instance.FontFace
	font.Weight = weight

	instance.FontFace = font
end

function Label.SetFontStyle(self: Label, style: Enum.FontStyle)
	local instance = self.Instance

	local font = instance.FontFace
	font.Style = style

	instance.FontFace = font
end

function Label.SetSize(self: Label, size: UDim2)
	self.Instance.Size = size
end

function Label.SetParent(self: Label, parent: Instance)
	self.Instance.Parent = parent
end

function Label.Destroy(self: Label)
	local instance = self.Instance

	instance:Destroy()
	self.Params:Destroy()

	for _, connection in self.Connections do
		connection:Disconnect()
	end
end

return Label
