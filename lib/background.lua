local advmath = require("advmath")
local logger = require("logger")
local background = {}
background.listens = {}
background.timers = {}

function background.addListen(func)
    table.insert(background.listens, func)
end

function background.removeListen(func)
    for index, value in ipairs(background.listens) do
        if value == func then
            table.remove(background.listens, index)
        end
    end
end

function background.addTimer(func, time)
    table.insert(background.timers, {func = func, time = time, lasttime = computer.uptime()})
end

function background.removeTimer(func)
    for index, value in ipairs(background.timers) do
        if value.func == func then
            table.remove(background.timers, index)
        end
    end
end

function background.call(func, ...)
    local data = {xpcall(func, debug.traceback, ...)}
    if not data[1] then
        logger.log("background-error", data[2])
    end
end

do
    local pullSignal = computer.pullSignal
    local uptime = computer.uptime
    local ipairs = ipairs
    local unpack = table.unpack
    local clamp = advmath.clamp
    local huge = math.huge
    local call = background.call

    function computer.pullSignal(time)
        time = time or huge

        local startTime = uptime()
        while uptime() - startTime <= time do
            for index, value in ipairs(background.timers) do --timers
                if uptime() - value.lasttime >= value.time then
                    value.lasttime = uptime()
                    call(value.func)
                end
            end

            local waittime = time - (uptime() - startTime) --подсчет сколько времяни остолось до ближайшего таймера
            for index, value in ipairs(background.timers) do
                local ltime = value.time - (uptime() - value.lasttime)
                if ltime < waittime then
                    waittime = ltime
                end
            end
            waittime = clamp(waittime, 0, huge)

            local data = {pullSignal(waittime)}
            if #data > 0 then
                for index, value in ipairs(background.listens) do
                    call(value, unpack(data))
                end
                return unpack(data)
            end
        end
    end
end

return background