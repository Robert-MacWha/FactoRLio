-- utils.lua
local utils = {}

function utils.split_string(str, delimiter)
    local result = {}
    local from = 1

    while true do
        local to = string.find(str, delimiter, from)
        if to == nil then break end

        table.insert(result, string.sub(str, from, to - 1))
        from = to + 1
    end

    table.insert(result, string.sub(str, from))
    return result
end

function utils.contains(tab, val)
    for _, value in ipairs(tab) do
        if value == val then
            return true
        end
    end
    return false
end

return utils