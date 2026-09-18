local VERSION = '0.0.0'

local Registry = require(script.Registry)
local Classes = require(script.Classes)
local Components = require(script.Components)
local Layouts = require(script.Layouts)
local GuiUtils = require(script.Utils.GuiUtils)

local Nova = {
	Version = VERSION,
	Registry = Registry,
	Classes = Classes,
	Components = Components,
	Layouts = Layouts,
}

function Nova.Init()
	local ScreenGui = Instance.new('ScreenGui')
	ScreenGui.Name = 'Nova v' .. VERSION
	ScreenGui.Parent = GuiUtils.GetStorage()
	ScreenGui.ResetOnSpawn = false
	ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	ScreenGui.AutoLocalize = false

	Registry.SetRootScreenGui(ScreenGui)
end

return Nova
