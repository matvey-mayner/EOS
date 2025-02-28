function math.round(number)
    return math.floor(number + 0.5)
end

-------------------------------------------------

function os.sleep(time, func)
    if not func then func = computer.pullSignal end

    local inTime = computer.uptime()
    while computer.uptime() - inTime < time do
        func(time - (computer.uptime() - inTime))
    end
end

-------------------------------------------------

function table.contains(tbl, element)
    for _, value in pairs(tbl) do
        if value == element then
            return true
        end
    end
    return false
end

function table.clone(t)
    local cache = {}
    local function recurse(tbl, newtbl)
        local newtbl = newtbl or {}
    
        for k, v in pairs(tbl) do
            if type(v) == "table" then
                local ltbl = cache[v]
                if not ltbl then
                    cache[v] = {}
                    ltbl = cache[v]
                    recurse(v, cache[v])
                end
                newtbl[k] = ltbl
            else
                newtbl[k] = v
            end
        end

        return newtbl
    end

    return recurse(t)
end

function table.removeMatches(tbl, v)
    for index, value in ipairs(tbl) do
        if value == v then
            table.remove(tbl, index)
            return true
        end
    end
    return false
end

function table.removeAllMatches(tbl, v)
    local finded = false
    for key, value in pairs(tbl) do
        if value == v then
            tbl[key] = nil
            finded = true
        end
    end
    return finded
end