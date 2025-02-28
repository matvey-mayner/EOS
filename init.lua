--[[
This is free and unencumbered software released into the public domain.

Anyone is free to copy, modify, publish, use, compile, sell, or
distribute this software, either in source code form or as a compiled
binary, for any purpose, commercial or non-commercial, and by any
means.

In jurisdictions that recognize copyright laws, the author or authors
of this software dedicate any and all copyright interest in the
software to the public domain. We make this dedication for the benefit
of the public at large and to the detriment of our heirs and
successors. We intend this dedication to be an overt act of
relinquishment in perpetuity of all present and future rights to this
software under copyright law.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.

For more information, please refer to <https://unlicense.org>
]]--


_G = _ENV

computer.setArchitecture("Lua 5.3")

bootaddress = computer.getBootAddress()
bootfs = component.proxy(bootaddress)

do
    local function raw_readFile(fs, path)
        checkArg(1, fs, "table", "string")
        checkArg(2, path, "string")
    
        if type(fs) == "string" then fs = component.proxy(fs) end
        if not fs.exists(path) then return nil, "file not found" end
        if fs.isDirectory(path) then return nil, "is directory" end
        local file, err = fs.open(path, "rb")
        if not file then return nil, err or "unknown" end
    
        local buffer = ""
        repeat
            local data = fs.read(file, math.huge)
            buffer = buffer .. (data or "")
        until not data
        fs.close(file)
        return buffer
    end
    _OSVERSION = raw_readFile(bootfs, "/version")

    function require(name)
        local path = "/lib/" .. name .. ".lua"
        local text = assert(raw_readFile(bootaddress, path))
        local code = assert(load(text, "raw=" .. path, "bt", _ENV))
        local lib = assert(code())
        return lib
    end
    
    local package = require("package")
    package._require("utilites")
    package._require("background")
end

---------------------------------------------------

require("webservices").run("/startup.lua")
require("autorun").autorun("autorun")

assert(require("programs").execute("desktop"))
