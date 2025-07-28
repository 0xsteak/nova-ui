type TableUtils = {
    DeepClone: <T>(t: T) -> T,
    MergeInto: (target: any, source: any) -> (),
    Merge: <T, U>(t1: T, t2: U) -> T & U
}

-- -- -- -- --

local TableUtils = {} :: TableUtils

function TableUtils.DeepClone(t)
    local clone = {}

    for index, value in pairs(t) do
        clone[index] = if typeof(value) == "table" then TableUtils.DeepClone(value) else value
    end

    return clone
end

function TableUtils.Merge(t1, t2)
    local result = {}

    if typeof(t1) == "table" then
        for index, value in t1 do
            result[index] = value
        end
    end

    if typeof(t2) == "table" then
        for index, value in t2 do
            result[index] = value
        end
    end

    return result
end

function TableUtils.MergeInto(target, source)
    for index, value in pairs(source) do
        target[index] = value
    end
end

return TableUtils