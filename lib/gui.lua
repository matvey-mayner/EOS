--[[
основа:
    чтобы начать работать с библиоткой gui нужно создать инстанц gui
    для этого вызовите метод create у библиотки gui
    передайте в него первым аргументом табличку настроек
    так же в этой табличке могут содержаться настройки рендера
    в вложеной табличке renderSettings, она будет передана библиотки drawer при создании инстанца
    ВНИМАНИЯ:
    интанц создавать НЕ НУЖНО, так как библиотека system делает это(system.gui)

вызов методов:
    вызов всех методов осуществяесь через :
    кроме методы создания инстанца gui из библиотеки

удаления обьектов(scene, layout, widget)
    если обькт вым больше не нужен, то вы должны вызвать метод destroy
    
цвета:
    цвета сдесь это таблицы с тремя значениями: bg, fg, char
    это позваляет делать дизиринг и много прикольных штук
    при этом bg и fg это цвета которые будет переданы на видюху,
    при этом если стоит флаг usingTheDefaultPalette, то цвета будут являться индексами палитры
    также можно передать и часло, и оно будет воспрянято как обычный цвет

сцены:
    сцены, это то где могут разпологаться элементы
    так же каждая сцена может содержать свою палитру
    для создании сцены вызовите метод createScene у инстанца gui
    при создании цвены должны быть переданы следующие аргументы:
        bg(цвет фона)
        sizeX(разрешения по X)
        sizeY(разрешения по Y)
        palette(палитра) - будет передана видеокарте заместо ее стандартной палитры
        usingTheDefaultPalette(использовать переданые цвета как индекс палитры)

layout:
    layout создаеться методом createLayout
    при этом должны быть переданы следующие аргументы:
        bg - цвет фона
        posX - позиция X
        posY - позиция Y
        sizeX - ширина X
        sizeY - ширина Y
        dragged - флаг, являеться ли layout перемашяемым
        doNotMoveToTheUpperLevel - флаг, если он установлен, то layout
        не будет перемешаться на активный план при взоимодействии с ним, идиально подходит для фонового layout
        
        scroll - флаг, являеться ли layout скролируемым(работает если есть элементы ниже отображения layout)

    на layout можно создавать дочернии layout, используя тот же метод createLayout
    при этом дочернии layout не смогут выходить за пределы родительского, и будут удалены в месте с ним

    так же некоторые параметры layout можно изменить после создания методом: setParam(name, value)
    и причитать используя getParam

    layout может быть отключеным и скрытым
    для упровления этими параметрами используйте:
        layout:setParam("hide", state)
        layout:setParam("disable", state)

    так же у layout есть несколько методов для автоматического создания элементов:
        createFullscreenText(text, bg, fg):widget - создает текст с указаными параметрами на
        весь layout начиная с ВТОРОЙ строки, чтобы было место для createLabel

        createControlButton(callback, char, bg, fg, pressed_bg, pressed_fg):widget - callback функция которая будет вызвана при нажатии кнопки
        createExitButton():widget - создает кнопку закрытия layout в верхнем правом углу
        createLabel(string):widget - создает label сверху layout,
        вызвать можно только если на первой строке layout нет элементов,
        кроме автоматически созданых унопок управления, кнопки упровления создать перед
        вызовом этого метода

widget:
    виджеты создаються на сценах методом createWidget
    который принимает таблицу настроек виджета
    так же некоторые параметры виджета можно изменить после создания методом: setParam(name, value)
    и причитать используя getParam

    основные поля таблицы:
        type - тип виджета
        posX
        posY
        sizeX
        sizeY
        bg - цвет фона
        fg - цвет текста
        disable - если true, то с виджетом нельзя будет взаимодействовать
        hide - если true, то виджет не будет видим

    так же большенство элементов поддерживают такие поля как bg, fg

    типы виджетов:
        label:
            просто лейбел, выводит текст из параметра text посиредине
        button:
            таботает как лейбел но может обрабатывать нажатия
            имеет дополнительные поля:
                pressed_bg, pressed_fg
                а так же togle - если true то это будет переключатель
                notAutoReleased - кнопка будет считаться отпушеной только если вы ее файтически отпустите
                
                onTogle - callback, будет вызван при нажатии и отпускании кнопки,
                первым аргументом будет передан ник игрона нажавшего на кнопку
                вторым текущее состояния кнопки
                работает во всех режимах кнопки

                onClick - callback, будет вызван при нажатии кнопки,
                первым аргументом будет передан ник игрона нажавшего на кнопку
                вторым текущее состояния кнопки

                onRelease - callback, будет вызван при отпускании кнопки,
                первым аргументом будет передан ник игрона нажавшего на кнопку
                вторым текущее состояния кнопки

                onReleaseInBox - callback, будет вызван при отпускании кнопки внутри самой кнопки,
                первым аргументом будет передан ник игрона нажавшего на кнопку
                вторым текущее состояния кнопки
                имеет смысл только с поднятом notAutoReleased, иначе будет просто вызван после onRelease
        plane:
            работает как label но не умеет выводить текст и поддерживает только bg цвет



]]

local drawer = require("drawer")
local advmath = require("advmath")
local colors = require("colors")
local parser = require("parser")
local system = require("system")
local computer = computer
local component = component
local unicode = unicode

----------------------------------------------FUNCS

local char_circle = "●"
local defaultcolor = {0, 0, " "}

local function fillFakeColor(self, posX, posY, sizeX, sizeY, text, bg, fg) --фековый цвет позваляет смешивать цвета символами unicode, и отрисовывать серый даже на экранах первого уровня
    self.drawzone:fill(posX, posY, sizeX, sizeY, table.unpack(bg))
    local centerX, centerY = math.floor(posX + (sizeX / 2)), math.floor(posY + (sizeY / 2))

    if text then
        local gstrs = {}
        for _, str in ipairs(parser.split(unicode, text, "\n")) do
            for _, str in ipairs(parser.toParts(unicode, str, sizeX)) do
                table.insert(gstrs, str)
            end
        end

        local index = 0
        for _, str in ipairs(gstrs) do
            index = index + 1
            if index > sizeY then break end
            local lbg = bg[1]
            local lfg = fg[1]
            if self.drawzone.depth == 1 and lbg == lfg then
                lfg = self.drawzone.maxFg
            end
            self.drawzone:set(centerX - math.floor(unicode.len(str) / 2), #gstrs > 1 and (posY + (index - 1)) or centerY, lbg, lfg, str)
        end
    end
end

local function touchInBox(box, eventData, startX, startY)
    if not startX then startX = 1 end
    if not startY then startY = 1 end
    local tx, ty = eventData[3] - (startX - 1), eventData[4] - (startY - 1)
    return tx >= box.posX and ty >= box.posY and tx < (box.posX + box.sizeX) and ty < (box.posY + box.sizeY), tx, ty
end

local function getColor(self, name, disableTable) --возврашяет цвет подходяший для вывода
    if type(name) == "number" then
        name = colors[name]
    end

    if self.drawzone.usingTheDefaultPalette then --если палитра
        return colors[name] --то вернуть индекс
    else
        if disableTable == nil and self.drawzone.depth > 1 then disableTable = true end
        
        if not disableTable then
            if name == "gray" then
                return {0, 0xFFFFFF, "▒"}
            elseif name == "lightGray" then
                return {0, 0xFFFFFF, "▓"}
            elseif name == "white" then
                return 0xFFFFFF
            elseif name == "black" then
                return 0
            else
                return {0, 0xFFFFFF, "░"}
            end
        else
            if self.drawzone.depth == 4 then --на мониторе второго тира, вернуть текущею палитру палитру
                if self.scene then
                    return self.scene.palette[colors[name]]
                else
                    if system.palette then
                        return system.palette[colors[name]]
                    else
                        return self.drawzone.palette[colors[name]]
                    end
                end
            end
            return drawer.palette_computercraft2[colors[name]] --а если не палитра, то цвета второго тира
        end
    end
end

--получить цвет в види табличи из обычного цвета, при этом с табличкой нечего не сделает
local function raw_mathColor(self, color, default)
    if color then
        if type(color) == "number" then
            return {color, 0, " "}
        else
            return color
        end
    else
        return raw_mathColor(self, default or defaultcolor)
    end
end

local function mathColor(self, color, default)
    return raw_mathColor(self, getColor(self, color), default)
end

local function callback(self, name, ...)
    local tbl = self
    return (tbl[name] or function() end)(...)
end

local function implement(obj)
    obj.timers = {}
    obj.listens = {}

    function obj._update(self)
        if self.destroyed then return end
        
        for index, value in ipairs(self.timers) do --timers
            if computer.uptime() - value.lasttime >= value.time then
                value.lasttime = computer.uptime()
                value.func()
            end
        end
        if self.layouts or self.childsLayouts then
            for _, layout in ipairs(self.layouts or self.childsLayouts) do
                if layout._update then
                    layout:_update()
                end
            end
        end
    end

    function obj._listen(self, eventData)
        if self.destroyed then return end

        for index, value in ipairs(self.listens) do
            value(table.unpack(eventData))
        end
        if self.layouts or self.childsLayouts then
            for _, layout in ipairs(self.layouts or self.childsLayouts) do
                if layout._listen then
                    layout:_listen(eventData)
                end
            end
        end
    end

    function obj.addTimer(self, func, time)
        table.insert(self.timers, {func = func, time = time, lasttime = computer.uptime()})
    end

    function obj.addListen(self, func)
        table.insert(self.listens, func)
    end

    function obj.removeListen(self, func)
        for index, value in ipairs(self.listens) do
            if value == func then
                table.remove(self.listens, index)
            end
        end
    end
    
    function obj.removeTimer(self, func)
        for index, value in ipairs(self.timers) do
            if value.func == func then
                table.remove(self.timers, index)
            end
        end
    end
end

----------------------------------------------WIDGET

local createWidget
do
    ----------------------------------------------functions

    local function mathPos(self)
        return self.posX + (self.layout.posX - 1), self.posY + (self.layout.posY - 1)
    end

    ----------------------------------------------callbacks

    local function listen(self, eventData)
        if self.disable then return end
        
        if self.type == "button" then
            local touchinbox = touchInBox(self, eventData, self.layout.posX, self.layout.posY)

            if self.togle then
                if eventData[1] == "touch" and touchinbox then
                    self.state = not self.state

                    self.gui:draw()

                    local sendDatas = {eventData[6], self.state, eventData}
                    callback(self, "onTogle", table.unpack(sendDatas))
                    if self.state then
                        callback(self, "onClick", table.unpack(sendDatas))
                    else
                        callback(self, "onRelease", table.unpack(sendDatas))
                        callback(self, "onReleaseInBox", table.unpack(sendDatas))
                    end
                end
            else
                if self.notAutoReleased then
                    --вы можете разом активировать несколько notAutoReleased кнопок просто свайпнув по ним, и разом отпустить отпустив кнопку мыши
                    if (eventData[1] == "touch" or eventData[1] == "drag") and touchinbox then
                        if not self.state then
                            self.state = true
                            self.gui:draw()

                            local sendDatas = {eventData[6], self.state, eventData}
                            callback(self, "onTogle", table.unpack(sendDatas))
                            callback(self, "onClick", table.unpack(sendDatas))
                        end
                    elseif eventData[1] == "drop" then
                        if self.state then
                           self.state = false
                            self.gui.redrawFlag = true

                            local sendDatas = {eventData[6], self.state, eventData}
                            callback(self, "onTogle", table.unpack(sendDatas))
                            callback(self, "onRelease", table.unpack(sendDatas))
                            if touchinbox then
                                callback(self, "onReleaseInBox", table.unpack(sendDatas))
                            end
                        end
                    end
                else
                    if eventData[1] == "touch" and touchinbox then
                        self.state = true
                        self.gui:draw()
                        --local uptime = computer.uptime()
                        local sendDatas = {eventData[6], self.state, eventData}
                        callback(self, "onTogle", table.unpack(sendDatas))
                        callback(self, "onClick", table.unpack(sendDatas))

                        self.state = false
                        self.gui:draw()
                        --local uptime = computer.uptime()
                        local sendDatas = {eventData[6], self.state, eventData}
                        callback(self, "onTogle", table.unpack(sendDatas))
                        callback(self, "onRelease", table.unpack(sendDatas))
                        callback(self, "onReleaseInBox", table.unpack(sendDatas))
                    end
                end
            end
            return touchinbox
        elseif self.type == "seek" then
            if eventData[1] == "touch" or eventData[1] == "drag" then
                local touchinbox, tx, ty = touchInBox(self, eventData, self.layout.posX, self.layout.posY)

                if touchinbox then
                    self.value = advmath.clampMap(tx - 1, 1, self.sizeX, self.min, self.max)
                    callback(self, "onSeek", self.value)

                    self.gui:draw()
                end

                return touchinbox
            end
        end
    end

    ----------------------------------------------interface

    local function destroy(self)
        table.removeMatches(self.layout.widgets, self)
        callback(self, "onDestroy")
    end

    local function draw(self)
        if self.hide then return end

        local posX, posY = mathPos(self)
        local centerX, centerY = posX + (math.round(self.sizeX / 2) - 1), posY + (math.round(self.sizeY / 2) - 1)
        
        if self.type == "text" or self.type == "button" or self.type == "plane" then
            local bg = mathColor(self, self.bg, getColor(self, "white"))
            local fg = mathColor(self, self.fg, getColor(self, "black"))
            local pressed_bg = mathColor(self, self.pressed_bg or self.fg, getColor(self, "black"))
            local pressed_fg = mathColor(self, self.pressed_fg or self.bg, getColor(self, "white"))
            
            fillFakeColor(self,
                posX,
                posY,
                self.sizeX,
                self.sizeY,
                self.type ~= "plane" and self.text,
                self.state and pressed_bg or bg,
                self.state and pressed_fg or fg
            )
        elseif self.type == "seek" then
            local bg = mathColor(self, self.bg, getColor(self, "gray"))
            local fg = mathColor(self, self.fg, getColor(self, "yellow"))
            local pressed_fg = mathColor(self, self.pressed_fg, getColor(self, "lime"))

            self.drawzone:fill(posX, posY, self.sizeX, self.sizeY, bg[1], fg[1], "|")
            self.drawzone:fill(posX, centerY, self.sizeX, 1, bg[1], getColor(self, "black"), "-")

            local px = posX + math.round(advmath.clampMap(self.value, self.min, self.max, 0, (self.sizeX - 1)))
            for i = 1, self.sizeY do
                self.drawzone:set(
                    px,
                    posY + (i - 1),
                    bg[1],
                    pressed_fg[1],
                    "|"
                )
            end
            self.drawzone:set(
                px,
                centerY,
                bg[1],
                getColor(self, "black"),
                char_circle
            )
        elseif self.type == "progress" then
            fillFakeColor(self,
                posX,
                posY,
                self.sizeX,
                self.sizeY,
                nil,
                mathColor(self, self.bg, getColor(self, "blue")),
                defaultcolor
            )
            fillFakeColor(self,
                posX,
                posY,
                math.round(advmath.clampMap(self.value, self.min, self.max, 0, self.sizeX)),
                self.sizeY,
                nil,
                mathColor(self, self.fg, getColor(self, "lime")),
                defaultcolor
            )
        elseif self.type == "list" then
            local bg = mathColor(self, self.bg, getColor(self, "yellow"))
            local fg = mathColor(self, self.fg, getColor(self, "orange"))
            local label_bg = mathColor(self, self.bg, getColor(self, "orange"))
            local label_fg = mathColor(self, self.fg, getColor(self, "yellow"))

            fillFakeColor(self,
                posX,
                posY,
                self.sizeX,
                self.sizeY,
                nil,
                bg,
                fg
            )
            fillFakeColor(self,
                posX,
                posY,
                self.sizeX,
                1,
                self.text,
                label_bg,
                label_fg
            )
        end
    end

    local function setParam(self, name, value)
        self[name] = value
    end

    local function getParam(self, name)
        return self[name]
    end

    function createWidget(self, settings)
        local widget = {}
        for key, value in pairs(settings) do
            widget[key] = value
        end
        widget.state = widget.state or false
        widget.value = widget.value or 0
        widget.min = widget.min or 0
        widget.max = widget.max or 1

        widget.destroy = destroy
        widget.draw = draw
        widget.setParam = setParam
        widget.getParam = getParam

        widget.listen = listen

        widget.layout = self
        self.drawzone:setUsingTheDefaultPalette(self.scene.usingTheDefaultPalette) --для правильной работы mathColor
        widget.drawzone = self.drawzone
        widget.maxFg = self.drawzone.maxFg
        widget.gui = self.scene.gui
        table.insert(self.widgets, widget)

        widget.gui.redrawFlag = true

        return widget
    end
end

----------------------------------------------LAYOUT

local createLayout
do
    local function destroy(self, autoCall)
        self.destroyed = true

        if self.parentLayout and not autoCall then
            table.removeMatches(self.parentLayout.childsLayouts, self)
        end

        for index, layout in ipairs(self.childsLayouts) do
            layout:destroy(true)
        end

        for index, widget in ipairs(self.widgets) do
            widget:destroy(true)
        end

        table.removeMatches(self.scene.layouts, self)
        self.scene.gui.redrawFlag = true
        callback(self, "onDestroy")
    end

    local function draw(self)
        if self.hide then return end
    
        self.drawzone:fill(self.posX, self.posY, self.sizeX, self.sizeY, table.unpack(self.bg))
        for _, widget in ipairs(self.widgets) do
            widget:draw()
        end
        for _, layout in ipairs(self.childsLayouts) do
            layout:draw()
        end
    end

    local function _move(self, x, y)
        local oldX, oldY = self.posX, self.posY
        self.posX = self.posX + x
        self.posY = self.posY + y
        if self.parentLayout then
            if self.posX < self.parentLayout.posX then
                self.posX = self.parentLayout.posX
            end
            if self.posY < self.parentLayout.posY then
                self.posY = self.parentLayout.posY
            end
            if self.posX > (self.parentLayout.posX + self.parentLayout.sizeX) - self.sizeX then
                self.posX = (self.parentLayout.posX + self.parentLayout.sizeX) - self.sizeX
            end
            if self.posY > (self.parentLayout.posY + self.parentLayout.sizeY) - self.sizeY then
                self.posY = (self.parentLayout.posY + self.parentLayout.sizeY) - self.sizeY
            end
        end
        local moveX, moveY = self.posX - oldX, self.posY - oldY

        for _, childLayout in ipairs(self.childsLayouts) do
            childLayout:_move(moveX, moveY)
        end
    end

    local function listen(self, eventData)
        if self.disable then return end


        local tx, ty = self.tx, self.ty
        if eventData[1] == "touch" or eventData[1] == "drag" then
            tx, ty = eventData[3], eventData[4]
        end

        local moveLock
        if not self.selected then
            for _, widget in ipairs(self.widgets) do
                if widget:listen(eventData) then
                    moveLock = true
                end
            end
        end

        if eventData[1] == "touch" then
            if not self.selected and not moveLock then
                self.selected = touchInBox(self, eventData)
            end
        elseif eventData[1] == "drop" then
            self.selected = false
        end

        if not self.lastLayout and not moveLock and self.selected and eventData[1] == "drag" and tx and self.tx and self.dragged then
            local moveX, moveY = tx - self.tx, ty - self.ty
            if moveX ~= 0 or moveY ~= 0 then
                self:_move(moveX, moveY)
                
                --self.scene.gui.redrawFlag = true
                self.scene.gui:draw()
            end
        end

        self.tx = tx
        self.ty = ty

        ------------------------------

        if eventData[1] == "touch" or eventData[1] == "drag" or eventData[1] == "scroll" then
            if self.lastLayout then
                if not self.lastLayout.selected then
                    self.lastLayout = nil
                else
                    self.lastLayout:listen(eventData)
                    return
                end
            end

            for i = #self.childsLayouts, 1, -1 do
                local layout = self.childsLayouts[i]
                if touchInBox(layout, eventData) then
                    if not layout.doNotMoveToTheUpperLevel then
                        table.remove(self.childsLayouts, i)
                        table.insert(self.childsLayouts, layout)
                    end
                    
                    layout:listen(eventData)
                    self.lastLayout = layout
                    self.scene.gui.redrawFlag = true
                    break
                end
            end
        else
            for _, layout in ipairs(self.childsLayouts) do
                layout:listen(eventData)
            end
        end
    end

    --------------------------------------------------------------auto creators

    local function createControlButton(self, callback, char, bg, fg, pressed_bg, pressed_fg)
        local widget = self:createWidget{
            type = "button",
        
            posX = self.sizeX - self.buttonvalue,
            posY = 1,
            sizeX = 1,
            sizeY = 1,
            text = char or " ",
        
            bg = getColor(self, "red"),
            fg = getColor(self, "white"),
            pressed_bg = getColor(self, "brown"),
            pressed_fg = getColor(self, "black"),
        
            notAutoReleased = true,

            onReleaseInBox = function()
                callback(self)
            end
        }
        self.buttonvalue = self.buttonvalue + 1
        return widget
    end

    local function createExitButton(self)
        return createControlButton(self, function()
            self:destroy()
        end, "X", getColor(self, "red"), getColor(self, "white"),
            getColor(self, "brown"), getColor(self, "black")
        )
    end

    local function createLabel(self, text)
        return self:createWidget({
            type = "text",
        
            posX = 1,
            posY = 1,
            sizeX = self.sizeX - self.buttonvalue,
            sizeY = 1,
            text = text,

            bg = mathColor(self, getColor(self, "white")),
            fg = mathColor(self, getColor(self, "black"))
        })
    end

    local function createFullscreenText(self, text, bg, fg)
        return self:createWidget({
            type = "text",
        
            posX = 1,
            posY = 2,
            sizeX = self.sizeX,
            sizeY = self.sizeY - 1,
            text = text,

            bg = bg or mathColor(self, getColor(self, "white")),
            fg = fg or mathColor(self, getColor(self, "black"))
        })
    end

    local function setParam(self, name, value)
        if name == "disable" then
            if not value then
                self.selected = false
            end
        end
        self[name] = value
    end

    local function getParam(self, name)
        return self[name]
    end

    local function toUpper(self)
        if self.parentLayout then
            assert(table.removeMatches(self.parentLayout.childsLayouts, self))
            table.insert(self.parentLayout.childsLayouts, self)
        else
            assert(table.removeMatches(self.scene.layouts, self))
            table.insert(self.scene.layouts, self)
        end
    end

    local function toDown(self)
        if self.parentLayout then
            assert(table.removeMatches(self.childsLayouts, self))
            table.insert(self.childsLayouts, 1, self)
        else
            assert(table.removeMatches(self.scene.layouts, self))
            table.insert(self.scene.layouts, 1, self)
        end
    end

    
    --doNotMoveToTheUpperLevel стоит использовать только для background layout`а, иначе вы можете сломать всю сцену
    function createLayout(self, bg, posX, posY, sizeX, sizeY, dragged, doNotMoveToTheUpperLevel, scroll)
        local layout = {}
        implement(layout)

        self.drawzone:setUsingTheDefaultPalette(self.usingTheDefaultPalette) --для правильной работы mathColor

        layout.bg = mathColor(self, bg)
        layout.posX = posX or 1
        layout.posY = posY or 1
        layout.sizeX = sizeX or self.gui.drawzone.maxSizeX
        layout.sizeY = sizeY or self.gui.drawzone.maxSizeY
        layout.dragged = dragged
        layout.doNotMoveToTheUpperLevel = doNotMoveToTheUpperLevel
        layout.buttonvalue = 0
        layout.scroll = scroll
        layout.widgets = {}
        layout.childsLayouts = {}

        layout.createWidget = createWidget

        layout.destroy = destroy
        layout.draw = draw
        layout.listen = listen
        layout.setParam = setParam
        layout.getParam = getParam

        layout.toUpper = toUpper
        layout.toDown = toDown

        layout.createLabel = createLabel
        layout.createFullscreenText = createFullscreenText
        layout.createExitButton = createExitButton

        layout.scene = self
        layout.drawzone = self.drawzone

        layout._move = _move

        layout.createLayout = function (oldlayout, bg, posX, posY, ...)
            posX = (posX + oldlayout.posX) - 1
            posY = (posY + oldlayout.posY) - 1
            local newlayout = oldlayout.scene:createLayout(bg, posX, posY, ...)
            newlayout.parentLayout = oldlayout
            table.insert(oldlayout.childsLayouts, newlayout)
            table.removeAllMatches(oldlayout.scene.layouts, newlayout)
            return newlayout
        end
        
        table.insert(self.layouts, layout)
        self.gui.redrawFlag = true
        return layout
    end
end

----------------------------------------------SCENE

local createScene
do
    local function destroy(self)
        self.destroyed = true

        for index, layout in ipairs(self.layouts) do
            layout:destroy()
        end

        table.removeMatches(self.gui.scenes, self)
        callback(self, "onDestroy")
    end

    local function draw(self)
        self.drawzone:clear(table.unpack(self.bg))
        for _, layout in ipairs(self.layouts) do
            layout:draw()
        end
    end

    

    local function listen(self, eventData)
        local upLayout = self.layouts[#self.layouts]
        if eventData[1] == "touch" or eventData[1] == "drag" or eventData[1] == "scroll" then
            if self.lastLayout then
                if not self.lastLayout.selected or self.lastLayout.disable then
                    self.lastLayout = nil
                else
                    self.lastLayout:listen(eventData)
                    return
                end
            end

            for i = #self.layouts, 1, -1 do
                local layout = self.layouts[i]
                if not layout.disable and touchInBox(layout, eventData) then
                    --если окно можно перемешять на верхник план, то перемешяем
                    if not layout.doNotMoveToTheUpperLevel then
                        table.remove(self.layouts, i)
                        table.insert(self.layouts, layout)
                    end
                    
                    layout:listen(eventData)
                    self.lastLayout = layout
                    self.gui.redrawFlag = true
                    break
                end
            end
        else
            for _, layout in ipairs(self.layouts) do
                layout:listen(eventData)
            end
        end
    end

    function createScene(self, bg, sizeX, sizeY, palette, usingTheDefaultPalette)
        local scene = {}
        implement(scene)

        self.drawzone:setUsingTheDefaultPalette(usingTheDefaultPalette) --для правильной работы mathColor
        
        scene.bg = mathColor(self, bg)
        scene.sizeX = sizeX or self.drawzone.maxSizeX
        scene.sizeY = sizeY or self.drawzone.maxSizeY
        scene.palette = palette
        scene.usingTheDefaultPalette = usingTheDefaultPalette
        scene.layouts = {}

        scene.listens = {}
        scene.timers = {}

        scene.destroy = destroy
        scene.draw = draw
        scene.listen = listen

        scene.createLayout = createLayout

        scene.gui = self
        scene.drawzone = self.drawzone
        table.insert(self.scenes, scene)
        return scene
    end
end

----------------------------------------------GUI

do
    local function listen(self, eventData)
        self.scene:_listen(eventData)
        if eventData[2] == self.drawzone.screen then
            self.scene:listen(eventData)
        elseif table.contains(self.keyboards, eventData[2]) then
            self.scene:listen(eventData)
        end 
    end

    local function tick(self)
        self.allowDraw = true
        if self.redrawFlag then
            self:draw()
            self.redrawFlag = nil
        end
    end

    local function exit(self)
        if self.running then
            self.running = false
            self.drawzone:destroy()
        end
    end

    local function run(self, func, time)
        time = time or 0.2

        tick(self)
        while self.running do
            local eventData = {computer.pullSignal(time)}
            self:listen(eventData)

            if self.scene then
                self.scene:_update()
            end

            tick(self)
            if func then
                func()
            end
        end
    end

    local function draw(self, force)
        if not self.allowDraw and not force then return end
        self.allowDraw = false

        self.drawzone:draw_begin()
        if self.scene then
            self.scene:draw()
        else
            self.drawzone:set(1, 1, "scene is not selected")
        end
        self.drawzone:draw_end()
    end

    local function selectScene(self, scene, force)
        self.scene = scene
        self.drawzone:setPalette(scene.palette)
        self.drawzone:setUsingTheDefaultPalette(scene.usingTheDefaultPalette)
        self.drawzone:setResolution(scene.sizeX, scene.sizeY, force)
        self.redrawFlag = true
        self.drawzone.flushed = true
    end

    local function create(settings)
        local obj = {redrawFlag = true}
        obj.running = true
        obj.settings = settings or {}
        obj.drawzone = drawer.create(obj.settings.renderSettings)
        obj.keyboards = component.invoke(obj.drawzone.screen, "getKeyboards")
        obj.scenes = {}

        obj.listen = listen
        obj.tick = tick
        obj.exit = exit
        obj.run = run
        obj.draw = draw
        obj.selectScene = selectScene

        obj.createScene = createScene

        obj.callback = callback
        obj.mathColor = mathColor
        obj.getColor = getColor
        return obj
    end

    return {create = create}
end