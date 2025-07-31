-- This module is recommended for use only with the 'bundle' version
-- If you're using 'source' or 'rbxm' version, require layouts directly

return setmetatable({}, {
    __index = function(self, index)
        if index == "ListLayout" then
            return require("@self/ListLayout")
        elseif index == "PageLayout" then
            return require("@self/PageLayout")
        elseif index == "GridLayout" then
            return require("@self/GridLayout")
        else
            error(`Layout '{index}' does not exist`)
        end
    end
})