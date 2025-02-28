local fs = require("filesystem")
local time = {}

function time.getRaw()
    local file = assert(fs.open("/tmp/getRealTime.null", "wb"))
    file.close()
    local time = fs.lastModified("/tmp/getRealTime.null")
    fs.remove("/tmp/getRealTime.null")

    return time
end



function time.getRealTime(timezone)
    local time = time.getRaw()
    local addToClock = timezone or 0

    -------------------------------------

    time = time / 1000
    time = time + (addToClock * 60 * 60)

    local seconds = time % 60
    local minutes = (time / 60) % 60
    local hours = (time / (60 * 60)) % 24

    return math.floor(hours), math.floor(minutes), math.floor(seconds)
end

function time.getGameTime()
    local time = os.time()

    local seconds = time % 60
    local minutes = (time / 60) % 60
    local hours = (time / (60 * 60)) % 24

    return math.floor(hours), math.floor(minutes), math.floor(seconds)
end

function time.formatTime(...)
    local args = {...}
    for index, value in ipairs(args) do
        value = tostring(value)
        if #value == 1 then value = "0" .. value end
        args[index] = value
    end
    return table.concat(args, ":")
end

return time