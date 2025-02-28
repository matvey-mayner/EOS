local fs = require("filesystem")
local time = require("time")
local user = require("user")
local logger = {}
logger.path = "/data/system_log.log"

function logger.log(...)
    local args = {...}
    for index, value in ipairs(args) do
        args[index] = tostring(value)
    end

    local timestr = time.formatTime(time.getRealTime(user.timezone))
    local logstr = table.concat(args, "  ")
    local endstr = timestr .. "> " .. logstr .. "\n"

    local file = fs.open(logger.path, "ab")
    if file then
        file.write(endstr)
        file.close()
    end
end

return logger