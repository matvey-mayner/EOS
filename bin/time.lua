local system = require("system")
local user = require("user")
local time = require("time")
local gui = system.gui
local scene = system.scene


local sizeX, sizeY = 25, 10
local posX, posY = scene.sizeX - 25, scene.sizeY - 10

local layout = scene:createLayout(
    "black",
    posX,
    posY,
    sizeX,
    sizeY,
    false
)

layout:createLabel("time")

realtime = layout:createWidget({
    type = "button",
    text = "",

    posX = 2,
    posY = 3,
    sizeX = sizeX - 2,
    sizeY = 1,

    bg = "white",
    pressed_bg = "white",
    fg = "black",
    pressed_fg = "black",

    onClick = function ()
        user.gametime = nil
    end
})

gametime = layout:createWidget({
    type = "button",
    text = "",

    posX = 2,
    posY = 4,
    sizeX = sizeX - 2,
    sizeY = 1,

    bg = "white",
    pressed_bg = "white",
    fg = "black",
    pressed_fg = "black",

    onClick = function ()
        user.gametime = true
    end
})

local function update()
    realtime:setParam("text", "realtime: " .. time.formatTime(time.getRealTime()))
    gametime:setParam("text", "gametime: " .. time.formatTime(time.getGameTime()))
    gui:draw()
end
layout:addTimer(update, 5)
update()

return layout