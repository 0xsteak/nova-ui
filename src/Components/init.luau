-- This module is recommended for use only with the 'bundle' version
-- If you're using 'source' or 'rbxm' version, require components directly

return setmetatable({}, {
    __index = function(self, index)
        if index == "Window" then
            return require("@self/Window")
        elseif index == "IconButton" then
            return require("@self/IconButton")
        elseif index == "ScrollView" then
            return require("@self/ScrollView")
        elseif index == "Container" then
            return require("@self/Container")
        else
            error(`Component '{index}' does not exist`)
        end
    end
})