local parser = {}

function parser.split(tool, str, seps)
    if type(seps) ~= "table" then
        seps = {tostring(seps)}
    end

    local parts = {""}
    local index = 1
    local strlen = tool.len(str)
    while index <= strlen do
        while true do
            local isBreak
            for i, sep in ipairs(seps) do
                if tool.sub(str, index, index + (tool.len(sep) - 1)) == sep then
                    table.insert(parts, "")
                    index = index + tool.len(sep)
                    isBreak = true
                    break
                end
            end
            if not isBreak then break end
        end

        parts[#parts] = parts[#parts] .. tool.sub(str, index, index)
        index = index + 1
    end

    return parts
end

function parser.toParts(tool, str, max)
    local strs = {}
    while tool.len(str) > 0 do
        table.insert(strs, tool.sub(str, 1, max))
        str = tool.sub(str, tool.len(strs[#strs]) + 1)
    end
    return strs
end

return parser