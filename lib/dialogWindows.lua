local system = require("system")
local gui = system.gui

--PS вместо scene вы можете передать layout при создании окна, чтобы оно появилось как дочернее

----------------------------------------------

local dialogWindows = {}
dialogWindows.windowSizeX = 35
dialogWindows.windowSizeY = 10

function dialogWindows.getWindowPos(scene, sizeX, sizeY)
    sizeX = sizeX or dialogWindows.windowSizeX
    sizeY = sizeY or dialogWindows.windowSizeY
    return math.round((scene.sizeX / 2) - (sizeX / 2)), math.round((scene.sizeY / 2) - (sizeY / 2))
end

function dialogWindows.getWindowSize(scene, minX, minY)
    return math.max(dialogWindows.windowSizeX, minX or -1), math.max(dialogWindows.windowSizeY, minY or -1)
end

----------------------------------------------

function dialogWindows.message(scene, label, text, color, textColor)
    scene = scene or system.scene
    color = color or "gray"
    textColor = textColor or "white"
    label = label or "alert message"
    text = text or ""

    local posX, posY = dialogWindows.getWindowPos(scene, dialogWindows.windowSizeX, dialogWindows.windowSizeY)
    local layout = scene:createLayout(
        color,
        posX,
        posY,
        dialogWindows.windowSizeX,
        dialogWindows.windowSizeY,
        true
    )
    layout:createExitButton()
    layout:createLabel(label)
    layout:createFullscreenText(text, color, textColor)

    local returnTbl = {}
    function layout.onDestroy()
        returnTbl.destroyed = true
        gui.callback(returnTbl, "onUpdate")
        gui.callback(returnTbl, "onDestroy")
    end
    return returnTbl, layout
end

function dialogWindows.selectColor(scene, label)
    scene = scene or system.scene
    label = label or "color pic"

    local sizeX = 12
    local sizeY = 7

    local posX, posY = dialogWindows.getWindowPos(scene, sizeX, sizeY)
    local layout = scene:createLayout(
        "gray",
        posX,
        posY,
        sizeX,
        sizeY,
        true
    )
    layout:createExitButton()
    layout:createLabel(label)

    local returnTbl = {}
    function layout.onDestroy()
        returnTbl.destroyed = true
        gui.callback(returnTbl, "onUpdate")
        gui.callback(returnTbl, "onDestroy")
    end

    local i = 0
    for x = 0, 3 do
        for y = 0, 3 do
            local currentI = i
            layout:createWidget({
                type = "button",
                notAutoReleased = true,

                posX = (x * 2) + 3,
                posY = y + 3,
                sizeX = 2,
                sizeY = 1,

                onReleaseInBox = function ()
                    returnTbl.color = currentI
                    gui.callback(returnTbl, "onUpdate", currentI)
                end,

                bg = i,
                pressed_bg = "white",
            })
            i = i + 1
        end
    end
    
    return returnTbl, layout
end

----------------------------------------------

function dialogWindows.error(scene, text)
    return dialogWindows.message(scene, "error", text, "red")
end

function dialogWindows.warning(scene, text)
    return dialogWindows.message(scene, "warning", text, "yellow")
end

return dialogWindows