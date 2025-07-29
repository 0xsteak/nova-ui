local Signal = require("./Signal")

-- -- -- -- --

type DragControllerImpl = {
    __index: DragControllerImpl,
    new: (adornee: GuiObject, dragHandle: GuiObject) -> DragController,
    Destroy: (self: DragController) -> ()
}

type self = {
    Class: "DragController",
    Adornee: GuiObject,
    DragHandle: GuiObject,
    Enabled: boolean,
    Locked: boolean,
    IsDragging: boolean,
    DragOffset: Vector2,
    DragChanged: Signal.Signal<UDim2>,
    Connections: {RBXScriptConnection}
}

export type DragController = typeof(setmetatable({} :: self, {} :: DragControllerImpl))

-- -- -- -- --

local DragController = {} :: DragControllerImpl
DragController.__index = DragController

local UserInputService = game:GetService("UserInputService")

local Controllers: {DragController} = {}
local beganInputType = if UserInputService.TouchEnabled then Enum.UserInputType.Touch else Enum.UserInputType.MouseButton1
local changedInputType = if UserInputService.TouchEnabled then Enum.UserInputType.Touch else Enum.UserInputType.MouseMovement

function DragController.new(adornee: GuiObject, dragHandle: GuiObject): DragController
    local self = setmetatable({}, DragController) :: DragController

    self.Class = "DragController"
    self.Adornee = adornee
    self.DragHandle = dragHandle
    self.Enabled = true
    self.Locked = false
    self.IsDragging = false
    self.DragChanged = Signal.new()
    
    local connections: {RBXScriptConnection} = {}

    connections[1] = dragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == beganInputType and self.Enabled and not self.Locked then
            if beganInputType == Enum.UserInputType.Touch and input.UserInputState ~= Enum.UserInputState.Begin then
                return
            end

            self.DragOffset = Vector2.new(adornee.AbsolutePosition.X - input.Position.X + adornee.AbsoluteSize.X * adornee.AnchorPoint.X, adornee.AbsolutePosition.Y - input.Position.Y + adornee.AbsoluteSize.Y * adornee.AnchorPoint.Y)

            self.IsDragging = true

            local connection: RBXScriptConnection
            connection = input.Changed:Connect(function()
                if input.UserInputState ~= Enum.UserInputState.End then return end

                self.IsDragging = false
                connection:Disconnect()
            end)
        end
    end)

    self.Connections = connections

    table.insert(Controllers, 1, self)

    return self
end

function DragController.Destroy(self: DragController)
    for _, connection in self.Connections do
        connection:Disconnect()
    end

    local index = table.find(Controllers, self)
    if index then
        table.remove(Controllers, index)
    end

    setmetatable(self :: any, {})
    table.clear(self :: any)
end

UserInputService.InputChanged:Connect(function(input)
    if input.UserInputType ~= changedInputType then return end

    for _, controller in Controllers do
        if not controller.IsDragging then continue end

        local dragOffset = controller.DragOffset
        local newPos = UDim2.fromOffset(input.Position.X + dragOffset.X, input.Position.Y + dragOffset.Y)

        controller.Adornee.Position = newPos
        controller.DragChanged:Fire(newPos)

        return
    end
end)

return DragController