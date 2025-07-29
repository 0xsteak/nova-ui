type IconImpl = {
    __index: IconImpl,
    new: (image: string, rectSize: Vector2?, rectOffset: Vector2?) -> Icon,
    ApplyTo: (self: Icon, object: ImageLabel) -> ()
}

type self = {
    Class: "Icon",
    Image: string,
    RectSize: Vector2,
    RectOffset: Vector2
}

export type Icon = typeof(setmetatable({} :: self, {} :: IconImpl))

-- -- -- -- --

local Icon = {} :: IconImpl
Icon.__index = Icon

function Icon.new(image: string, rectSize: Vector2?, rectOffset: Vector2?): Icon
    local self = setmetatable({}, Icon) :: Icon

    self.Class = "Icon"
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

return Icon