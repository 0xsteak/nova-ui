local VERSION = "0.0.0"

-- -- -- -- --

local Registry = require("@self/Modules/Registry")
local Classes = require("@self/Classes")
local Components = require("@self/Components")
local GuiUtils = require("@self/Utils/GuiUtils")

-- -- -- -- --

type Nova = {
    Version: string,
    Registry: typeof(Registry),
    Classes: typeof(Classes),
    Components: typeof(Components),
    Init: () -> ()
}

-- -- -- -- --

local Nova = {
    Version = VERSION,
    Registry = Registry,
    Classes = Classes,
    Components = Components
} :: Nova

function Nova.Init()
	local ScreenGui = Instance.new("ScreenGui")
	ScreenGui.Name = "Nova v" .. VERSION
	ScreenGui.Parent = assert(GuiUtils.GetStorage(), "Nova: Cannot find storage for ScreenGui")
	ScreenGui.ResetOnSpawn = false
	ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.AutoLocalize = false

	Registry.Settings.ScreenGui = ScreenGui
end

return Nova