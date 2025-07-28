local Signal = require("./Signal")

-- -- -- -- --

type DragControllerImpl = {
    __index: DragControllerImpl,
    new: (object: GuiObject, dragHandle: GuiObject) -> DragController,
    Destroy: (self: DragController) -> ()
}

type self = {
    Object: GuiObject,
    Handle: GuiObject,
    Enabled: boolean,
    Locked: boolean,
    IsDragging: boolean,
    DragOffset: Vector2,
    DragChanged: Signal.Signal<UDim2>,
    Connections: {RBXScriptConnection}
}

export type DragController = typeof(setmetatable({} :: self, {} :: DragControllerImpl))

-- -- -- -- --

local DragController = {}
DragController.__index = DragController

local UserInputService = game:GetService("UserInputService")

local Controllers: {DragController} = {}
local beganInputType = if UserInputService.TouchEnabled then Enum.UserInputType.Touch else Enum.UserInputType.MouseButton1
local changedInputType = if UserInputService.TouchEnabled then Enum.UserInputType.Touch else Enum.UserInputType.MouseMovement

function DragController.new(object: GuiObject, dragHandle: GuiObject): DragController
    local self = setmetatable({}, DragController) :: DragController

    self.Object = object
    self.Handle = dragHandle
    self.Enabled = true
    self.Locked = false
    self.IsDragging = false
    self.DragChanged = Signal.new()
    
    local connections: {RBXScriptConnection} = {}

    -- local isDragging = false
    -- local dragOffset: Vector2

    connections[1] = dragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == beganInputType and self.Enabled and not self.Locked then
            if beganInputType == Enum.UserInputType.Touch and input.UserInputState ~= Enum.UserInputState.Begin then
                return
            end

            self.DragOffset = Vector2.new(object.AbsolutePosition.X - input.Position.X + object.AbsoluteSize.X * object.AnchorPoint.X, object.AbsolutePosition.Y - input.Position.Y + object.AbsoluteSize.Y * object.AnchorPoint.Y)

            -- isDragging = true
            self.IsDragging = true


            local connection: RBXScriptConnection
            connection = input.Changed:Connect(function()
                if input.UserInputState ~= Enum.UserInputState.End then return end

                -- isDragging = false
                self.IsDragging = false
                connection:Disconnect()
            end)
        end
    end)

    -- connections[2] = UserInputService.InputChanged:Connect(function(input)
    --     if input.UserInputType == changedInputType and isDragging then
    --         local newPos = UDim2.fromOffset(input.Position.X + dragOffset.X, input.Position.Y + dragOffset.Y)

    --         object.Position = newPos
    --         self.DragChanged:Fire(newPos)
    --     end
    -- end)

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

        controller.Object.Position = newPos
        controller.DragChanged:Fire(newPos)

        return
    end
end)

return DragController