local webservices = require("webservices")
local autorun = require("autorun")
local programs = require("programs")
local system = require("system")
local fs = require("filesystem")
local user = require("user")
local background = require("background")
local time = require("time")

local gui = system.gui

-------------------------------------------------------

scene = system.createScene()
system.scene = scene

bgLayout = scene:createLayout(user.color_background, 1, 1, system.rx, system.ry, false, true)

menuPlane = bgLayout:createWidget({
    type = "plane",

    bg = user.color_plane,

    posX = 1,
    posY = bgLayout.sizeY,
    sizeX = bgLayout.sizeX,
    sizeY = 1
})

anytime = bgLayout:createWidget({
    type = "button",
    text = "00:00:00",

    bg = user.color_plane,
    pressed_bg = user.color_plane,
    fg = "white",
    pressed_fg = "white",

    onClick = function ()
        if timemenu then
            timemenu:destroy()
            timemenu = nil
            return
        end
        timemenu = programs.guiout_execute("time")
    end,

    posX = bgLayout.sizeX - 9,
    posY = bgLayout.sizeY,
    sizeX = 8,
    sizeY = 1
})

osButton = bgLayout:createWidget({
    type = "button",
    text = "OS",

    togle = true,
    onTogle = function (_, state)
        osMenu:toUpper()
        osMenu:setParam("disable", not state)
        osMenu:setParam("hide", not state)
        powerMenu:setParam("disable", true)
        powerMenu:setParam("hide", true)
        powerButton:setParam("state", false)
    end,

    bg = "blue",
    fg = "lightBlue",

    posX = 1,
    posY = bgLayout.sizeY,
    sizeX = 4,
    sizeY = 1
})

osMenu = scene:createLayout("gray", 1, scene.sizeY - 10, 30, 10)
osMenu:setParam("disable", true)
osMenu:setParam("hide", true)
powerButton = osMenu:createWidget({
    type = "button",
    togle = true,

    text = "Power",

    posX = 1,
    posY = osMenu.sizeY,
    sizeX = 8,
    sizeY = 1,

    onTogle = function (_, state)
        powerMenu:setParam("disable", not state)
        powerMenu:setParam("hide", not state)
    end
})

powerMenu = osMenu:createLayout("lightGray", 2, osMenu.sizeY - 5, 10, 5)
powerMenu:setParam("disable", true)
powerMenu:setParam("hide", true)
powerMenu:createWidget({
    type = "button",
    notAutoReleased = true,

    text = "Reboot",

    posX = 1,
    posY = powerMenu.sizeY - 1,
    sizeX = powerMenu.sizeX,
    sizeY = 1,

    onReleaseInBox = function ()
        computer.shutdown(true)
    end
})
powerMenu:createWidget({
    type = "button",
    notAutoReleased = true,

    text = "Shutdown",

    posX = 1,
    posY = powerMenu.sizeY,
    sizeX = powerMenu.sizeX,
    sizeY = 1,

    onReleaseInBox = function ()
        computer.shutdown()
    end
})

-------------------------------------------------------apps menu

apps_list = {}
apps_buttons = {}
function refreshApps()
    apps_list = {}
    for _, data in ipairs(programs.list()) do
        if fs.isDirectory(data.path) then
            table.insert(apps_list, data)
        end
    end


    for _, app_button in ipairs(apps_buttons) do
        app_button:destroy()
    end
    apps_buttons = {}
    for i, app in ipairs(apps_list) do
        table.insert(apps_buttons, bgLayout:createWidget({
            type = "button",

            text = app.name,

            posX = 2,
            posY = 1 + i,
            sizeX = 16,
            sizeY = 1,

            onClick = function (_, _, eventData)
                local press_type = eventData[5]

                if press_type == 0 then
                    programs.guiout_execute(app.path)
                else

                end
            end
        }))
    end
end

refreshApps()

-------------------------------------------------------

scene:addListen(function (name)
    if name == "refresh_desktop" then
        bgLayout.bg = gui:mathColor(user.color_background)
        refreshApps()
        gui:draw()
    end
end)

scene:addTimer(function ()
    if user.gametime then
        anytime:setParam("text", time.formatTime(time.getGameTime()))
    else
        anytime:setParam("text", time.formatTime(time.getRealTime()))
    end
    gui:draw()
end, 5)

gui:selectScene(scene)
webservices.run("/desktop.lua")
autorun.autorun("desktopAutorun")
gui:run()