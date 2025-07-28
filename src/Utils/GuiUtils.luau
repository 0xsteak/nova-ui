type GuiUtils = {
    GetCenterPosition: (object: GuiObject) -> (),
    GetStorage: () -> CoreGui | PlayerGui,
}

-- -- -- -- --

local GuiUtils = {} :: GuiUtils

function GuiUtils.GetCenterPosition(object: GuiObject)
    local absoluteSize = object.AbsoluteSize
    local offsetX = (absoluteSize.X / 2) - (object.AnchorPoint.X * absoluteSize.X)
    local offsetY = (absoluteSize.Y / 2) - (object.AnchorPoint.Y * absoluteSize.Y)
    return UDim2.new(0.5, -offsetX, 0.5, -offsetY)
end

function GuiUtils.GetStorage(): CoreGui | PlayerGui
    local gethui = gethui or get_hidden_gui or get_hidden_ui
    local hiddenStorage = typeof(gethui) == "function" and gethui()

    if hiddenStorage then
        return hiddenStorage
    end

    local success, storage = pcall(function()
        local CoreGui = game:GetService("CoreGui")
        return CoreGui.Name and CoreGui
    end)

    if success then
        return storage
    end

    return game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui") :: PlayerGui
end

return GuiUtils