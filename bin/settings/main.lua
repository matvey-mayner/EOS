local dialogWindows = require("dialogWindows")
local system = require("system")
local user = require("user")
local gui = system.gui
local scene = system.scene


local sizeX, sizeY = dialogWindows.getWindowSize(scene, 40, 10)
local posX, posY = dialogWindows.getWindowPos(scene, sizeX, sizeY)

local layout = scene:createLayout(
    "black",
    posX,
    posY,
    sizeX,
    sizeY,
    true
)

layout:createExitButton()
layout:createLabel("settings")

layout:createWidget({
    type = "button",
    text = "set background color",

    posX = 2,
    posY = 3,
    sizeX = 24,
    sizeY = 1,

    onClick = function ()
        dialogWindows.selectColor(scene).onUpdate = function (color)
            if color then
                user.color_background = color
                system.refresh_desktop()
            end
        end
    end
})