local package = {}
package.loaded = {
    package = package,
    math = math,
    table = table,
    computer = computer,
    component = component,
    unicode = unicode,
    utf8 = utf8,
    filesystem = require("filesystem"),
    env = require("env"),
}
package.paths = {"/lib", "/data/lib"}

function package._require(name)
    checkArg(1, name, "string")
    if package.loaded[name] then return package.loaded[name] end

    local filesystem = require("filesystem")
    local env = require("env")

    local lib, finded
    for index, value in ipairs(package.paths) do
        local path = filesystem.concat(value, name .. ".lua")

        if filesystem.exists(path) then
            local text = assert(filesystem.readFile(path))
            local code = assert(load(text, "=" .. path, "bt", env.createProgrammEnv()))
            lib = code()
            
            finded = true
            break
        end
    end

    if not finded then
        error("lib " .. name .. " not found")
    end

    package.loaded[name] = lib or true

    -----------------------------------

    return lib or true
end

function package.require(name)
    return setmetatable({}, {
        __index = function (self, key)
            local lib = package._require(name)
            if type(lib) == "table" then
                return lib[key]
            else
                return lib
            end
        end,
        __newindex = function (self, key, value)
            local lib = package._require(name)
            if type(lib) == "table" then
                lib[key] = value
            end
        end,
    })
end

require = package.require
return package