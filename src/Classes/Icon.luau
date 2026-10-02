type IconProps = {
	Image: string,
	RectSize: Vector2,
	RectOffset: Vector2,
}

local Icon = {}
Icon.__index = Icon

Icon.ClassName = 'NovaUI.Icon'

export type Icon = typeof(setmetatable({} :: IconProps, Icon))

function Icon.__tostring(self: Icon)
	return Icon.ClassName
end

function Icon.new(image: string, rectSize: Vector2?, rectOffset: Vector2?): Icon
	local self: Icon = setmetatable({}, Icon)

	self.Image = image
	self.RectSize = rectSize or Vector2.zero
	self.RectOffset = rectOffset or Vector2.zero

	return self
end

function Icon.ApplyTo(self: Icon, object: ImageLabel)
	object.Image = self.Image
	object.ImageRectSize = self.RectSize
	object.ImageRectOffset = self.RectOffset
end

Icon.empty = Icon.new('')

return Icon
