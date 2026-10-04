local TableUtils = require(script.Parent.Parent.Utils.TableUtils)
local Blueprint = require(script.Parent.Parent.Classes.Blueprint)
local ThemeService = require(script.Parent.Parent.Services.ThemeService)
local Preferences = require(script.Parent.Parent.Registry.Preferences)
local TextService = game:GetService('TextService')
local Signal = require(script.Parent.Parent.Packages.Signal)

type DisplayMode = 'Fixed' | 'AutoHeight'

type LabelProps = {
	Base: TextLabel,
	DisplayMode: DisplayMode,
	_params: GetTextBoundsParams,
	_connections: { Signal.Connection },
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

	local base: TextLabel = self.Base
	local params = self._params
	local width = base.AbsoluteSize.X

	params.Text = base.Text
	params.Width = width
	params.Size = base.TextSize
	params.Font = base.FontFace

	local currentThreadId = self._updateThreadId + 1
	self._updateThreadId = currentThreadId

	local height = TextService:GetTextBoundsAsync(params).Y

	if self._updateThreadId ~= currentThreadId then
		return
	end

	base.Size = UDim2.new(base.Size.X.Scale, base.Size.X.Offset, 0, height)
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

	local base = BaseBlueprint:Build() :: TextLabel

	self.Base = base
	self.DisplayMode = options.DisplayMode
	self._updateThreadId = 0

	local connections = {}

	local params = Instance.new('GetTextBoundsParams')
	self._params = params

	local function updateThisHeight()
		updateHeight(self)
	end

	local lastWidth = base.AbsoluteSize.X
	base:GetPropertyChangedSignal('AbsoluteSize'):Connect(function()
		local width = base.AbsoluteSize.X
		if width ~= lastWidth then
			updateThisHeight()
			lastWidth = width
		end
	end)
	base:GetPropertyChangedSignal('Text'):Connect(updateThisHeight)
	base:GetPropertyChangedSignal('TextSize'):Connect(updateThisHeight)
	base:GetPropertyChangedSignal('FontFace'):Connect(updateThisHeight)

	ThemeService.Bind(base, 'PrimaryText', 'TextColor3')
	ThemeService.Update()

	self:SetText(options.Text)
	self:SetXAlignment(options.TextXAlignment)
	self:SetYAlignment(options.TextYAlignment)
	self:SetTextSize(options.TextSize)
	self:SetTextTruncate(options.TextTruncate)
	self:SetTextWrapped(options.DisplayMode == 'AutoHeight' and true or options.TextWrapped)
	self:SetSize(options.Size)

	connections[1] = Preferences.FontFamilyChanged:Connect(function(newFamily: string)
		local font = base.FontFace
		font.Family = newFamily

		base.FontFace = font
	end)

	self._connections = connections

	return self
end

function Label.SetText(self: Label, text: string)
	self.Base.Text = text
end

function Label.SetXAlignment(self: Label, alignment: Enum.TextXAlignment)
	self.Base.TextXAlignment = alignment
end

function Label.SetYAlignment(self: Label, alignment: Enum.TextYAlignment)
	self.Base.TextYAlignment = alignment
end

function Label.SetTextSize(self: Label, size: number)
	self.Base.TextSize = size
end

function Label.SetTextTruncate(self: Label, value: Enum.TextTruncate)
	self.Base.TextTruncate = value
end

function Label.SetTextWrapped(self: Label, wrapped: boolean)
	self.Base.TextWrapped = wrapped
end

function Label.SetFontWeight(self: Label, weight: Enum.FontWeight)
	local base = self.Base

	local font = base.FontFace
	font.Weight = weight

	base.FontFace = font
end

function Label.SetFontStyle(self: Label, style: Enum.FontStyle)
	local base = self.Base

	local font = base.FontFace
	font.Style = style

	base.FontFace = font
end

function Label.SetSize(self: Label, size: UDim2)
	self.Base.Size = size
end

function Label.SetParent(self: Label, parent: Instance)
	self.Base.Parent = parent
end

function Label.Destroy(self: Label)
	local base = self.Base

	base:Destroy()
	self._params:Destroy()

	for _, connection in self._connections do
		connection:Disconnect()
	end
end

return Label
