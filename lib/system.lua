local gui = require("gui")
local drawer = require("drawer")
local parser = require("parser")
local internet = require("internet")
local json = require("json")
local logger = require("logger")
local fs = require("filesystem")
local user = require("user")

---------------------------

local system = {}
system.gui = gui.create()
system.palette = drawer.palette_computercraft2
system.usingTheDefaultPalette = true --если включить, то цвета будут представлять собоий индексы палитры, в то время как цвета вне палитры будут недоступны
system.rx = system.gui.drawzone.maxSizeX
system.ry = system.gui.drawzone.maxSizeY

--[[
--палитра не будет устоновлена на мониторах третиго уровня
--это освабодит серый цвет для отрисовки картинок
if system.gui.drawzone.depth ~= 4 then
    system.palette = nil
    system.usingTheDefaultPalette = nil
end
]]

function system.getSelfInfo()
    local info

    for runLevel = 0, math.huge do
        info = debug.getinfo(runLevel)

        if info then
            if info.what == "main" then
                return parser.split(string, info.source, "=")
            end
        else
            error("Failed to get debug info for runlevel " .. runLevel)
        end
    end
end

function system.getSelfPath()
    return system.getSelfInfo()[2]
end

function system.getSelfType()
    return system.getSelfInfo()[1]
end

function system.createScene(bg, sizeX, sizeY, palette)
    return system.gui:createScene(
        bg,
        sizeX or system.rx,
        sizeY or system.ry,
        palette or system.palette,
        system.usingTheDefaultPalette
    )
end

function system.refresh_desktop()
    computer.pushSignal("refresh_desktop")
    system.palette = user.palette or drawer.palette_computercraft2
end

-------------------------------------------------

local folder = "/os"
local user = "igorkll"
local repo = "liteOS"
local branch = "main"

function system.update()
    local files = assert(internet.repoList(user, repo, folder))
    for _, path in ipairs(files) do
        local repopath = fs.concat(folder, path)
        local url = internet.repoUrl(user, repo, branch, repopath)
        local data = internet.wget(url)
        if data then
            fs.writeFile(path, data)
        end
    end
end

function system.actualVersion()
    return internet.wget(internet.repoUrl(user, repo, branch, fs.concat(folder, "version")))
end

function system.needUpdate()
    return _OSVERSION ~= system.actualVersion()
end

return system