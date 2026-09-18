-- This module is recommended for use only with the 'bundle' version

local Components = {}

for _, child in script:GetChildren() do
	if child:IsA('ModuleScript') then
		Components[child.Name] = require(child)
	end
end

Components.Buttons = {}
for _, child in script.Buttons:GetChildren() do
	if child:IsA('ModuleScript') then
		Components.Buttons[child.Name] = require(child)
	end
end

return Components
