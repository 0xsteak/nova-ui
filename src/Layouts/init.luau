-- This module is recommended for use only with the 'bundle' version

local Layouts = {}

for _, child in script:GetChildren() do
	if child:IsA('ModuleScript') then
		Layouts[child.Name] = require(child)
	end
end

return Layouts
