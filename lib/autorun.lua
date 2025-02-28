local fs = require("filesystem")
local logger = require("logger")
local autorun = {}

function autorun._autorun(folder)
    local fs = require("filesystem")
    local programs = require("programs")
    if fs.exists(folder) and fs.isDirectory(folder) then
        for _, path in ipairs(fs.list(folder) or {}) do
            local fullpath = fs.concat(folder, path)
            if fs.exists(fullpath) then
                local ok, err = programs.execute(fullpath)
                if not ok then
                    logger.log("autorun-error", fullpath, err)
                end
            end
        end
    end
end

function autorun.autorun(name)
    autorun._autorun(fs.concat("/", name))
    autorun._autorun(fs.concat("/data", name))
end

return autorun