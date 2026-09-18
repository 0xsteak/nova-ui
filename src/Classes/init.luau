-- This module is recommended for use only with the 'bundle' version

local Classes = {}

for _, child in script:GetChildren() do
	if child:IsA('ModuleScript') then
		Classes[child.Name] = require(child)
	end
end

return Classes
