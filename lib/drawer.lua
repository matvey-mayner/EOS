--[[
    для коректной отрисовке необходимо сначала вызвать draw_begin
    отрисовать все что необходимо а зачем вызвать draw_end
    между draw_begin и draw_end не должно быть прирываний(тех что могут переключить процесс)
    так же в блоке отрисовке нужно вызывать только draw utiles методы методы settings следует вызывать до него
]]

local softwareBuffer = require("softwareBuffer")
local advmath = require("advmath")
local drawer = {}

 --красивый список цветов, рекомендую использовать даже не третим тире, чтобы программа везде выглядела одинакого
drawer.palette_defaultTier2 = {[0] = 16777215.0,16763955.0,13395660.0,6724095.0,16777011.0,3394611.0,16737945.0,3355443.0,13421772.0,3368601.0,10040268.0,3355545.0,6697728.0,3368448.0,16724787.0,0.0}
 --от белого к черному
drawer.palette_defaultTier3 = {[0] = 986895.0,1973790.0,2960685.0,3947580.0,4934475.0,5921370.0,6908265.0,7895160.0,8882055.0,9868950.0,10855845.0,11842740.0,12829635.0,13816530.0,14803425.0,15790320.0}

drawer.palette_computercraft = { --цвета computercraft
    [0] = 0xF0F0F0, --1)  white
    0xF2B233, --2)  orange
    0xE57FD8, --3)  magenta
    0x99B2F2, --4)  lightBlue
    0xDEDE6C, --5)  yellow
    0x7FCC19, --6)  lime
    0xF2B2CC, --7)  pink
    0x4C4C4C, --8)  gray
    0x999999, --9)  lightGray
    0x4C99B2, --10) cyan
    0xB266E5, --11) purple
    0x3366CC, --12) blue
    0x7F664C, --13) brown
    0x57A64E, --14) green
    0xCC4C4C, --15) red
    0x191919  --16) black
}

--модифицированые цвета computercraft отпимизированые под вывод на мониторе третиго уровня без изменения штатной палитры
drawer.palette_computercraft2 = {
    [0] = 0xFFFFFF, --1)  white
    0xF2B233, --2)  orange
    0xE57FD8, --3)  magenta
    0x99B2F2, --4)  lightBlue
    0xDEDE6C, --5)  yellow
    0x7FCC19, --6)  lime
    0xF2B2CC, --7)  pink
    0x4C4C4C, --8)  gray
    0x999999, --9)  lightGray
    0x4C99B2, --10) cyan
    0xB266E5, --11) purple
    0x3366CC, --12) blue
    0x7F664C, --13) brown
    0x57A64E, --14) green
    0xCC4C4C, --15) red
    0x000000  --16) black
}


function drawer.create(settings) --создает графическую системму, состоящию из видеокарты и монитора
    checkArg(1, settings, "table", "nil")
    settings = settings or {}

    local gpu = component.proxy((settings.gpu or component.list("gpu")()) or "")
    local screen = settings.screen or component.list("screen")()
    if gpu and screen then
        if not settings.doNotAutoOn then
            component.invoke(screen, "turnOn")
        end
        if not settings.doNotDisablePrecise then
            component.invoke(screen, "setPrecise", false)
        end

        local obj = setmetatable({
            gpu = gpu,
            screen = screen,

            settings = settings,
        }, {__index = drawer})

        gpu.bind(screen)
        local mx, my = gpu.maxResolution()
        local rx, ry = settings.rx or mx, settings.ry or my


        if settings.allowHardwareBuffer == nil then --если значения не false не true то оно будет по умалчанию
            settings.allowHardwareBuffer = true
        end
        if settings.allowCombineBuffers == nil then
            settings.allowCombineBuffers = false
        end
        if settings.softwareBufferPriority == nil then
            settings.softwareBufferPriority = true
        end
        if settings.allowSoftwareBuffer == nil then
            settings.allowSoftwareBuffer = (computer.freeMemory() / 3) > (rx * ry * 32)
        end

        --[[
        if settings.allowSoftwareBuffer then
            computer.beep(2000)
        else
            computer.beep(100)
        end
        ]]

        gpu.setDepth(1) --сброс палитры
        gpu.setDepth(gpu.maxDepth())

        gpu.setResolution(rx, ry) --ставим максимальное разрешения

        gpu.setBackground(0) --цвета по умалчанию
        gpu.setForeground(0xFFFFFF)

        gpu.fill(1, 1, rx, ry, " ") --очистка экрана

        obj.depth = settings.depth or gpu.getDepth()
        obj.sizeX = rx
        obj.sizeY = ry

        obj.maxSizeX = mx
        obj.maxSizeY = my

        gpu.setDepth(obj.depth)

        ------------------------------------
        
        if obj.depth > 1 then
            obj.palette = {}
            for i = 0, 15 do
                obj.palette[i] = (settings.palette and settings.palette[i]) or gpu.getPaletteColor(i)
            end
        else
            settings.usingTheDefaultPalette = nil
        end

        obj:setUsingTheDefaultPalette(settings.usingTheDefaultPalette) --если включить, то методы будует принимать цвета сразу в индексах палирт

        if gpu.setActiveBuffer then
            obj.bufferSupport = true
        end
        
        if settings.allowCombineBuffers then
            if obj.bufferSupport and settings.allowHardwareBuffer then
                obj.hardwareBuffer = gpu.allocateBuffer(obj.sizeX, obj.sizeY)
            end
            if settings.allowSoftwareBuffer then
                obj.softwareBuffer = softwareBuffer.create(gpu.address, settings.usingTheDefaultPalette)
            end
        else
            if settings.softwareBufferPriority then
                if settings.allowSoftwareBuffer then
                    obj.softwareBuffer = softwareBuffer.create(gpu.address, settings.usingTheDefaultPalette)
                elseif obj.bufferSupport and settings.allowHardwareBuffer then
                    obj.hardwareBuffer = gpu.allocateBuffer(obj.sizeX, obj.sizeY)
                end
            else
                if obj.bufferSupport and settings.allowHardwareBuffer then
                    obj.hardwareBuffer = gpu.allocateBuffer(obj.sizeX, obj.sizeY)
                elseif settings.allowSoftwareBuffer then
                    obj.softwareBuffer = softwareBuffer.create(gpu.address, settings.usingTheDefaultPalette)
                end
            end
        end

        obj.flushed = true
        return obj
    end
end

------------------------------------------------------------------------settings

function drawer:_begin()
    if self.gpu.getScreen() ~= self.screen then
        self.gpu.bind(self.screen, false)
    end
    if self.bufferSupport then
        self.gpu.setActiveBuffer(0)
    end
end

function drawer:setResolution(rx, ry, force)
    checkArg(1, rx, "number")
    checkArg(2, ry, "number")

    if self.sizeX == rx and self.sizeY == ry and not force then
        return false
    end

    self:_begin()
    self.gpu.setResolution(rx, ry)
    if self.bufferSupport and self.hardwareBuffer then
        local newbuffer = self.gpu.allocateBuffer(rx, ry)
        self.gpu.bitblt(newbuffer, nil, nil, nil, nil, self.hardwareBuffer)
        self.gpu.freeBuffer(self.hardwareBuffer)
        self.hardwareBuffer = newbuffer
    end

    self.sizeX = rx
    self.sizeY = ry
    return true
end

function drawer:getResolution()
    return self.sizeX, self.sizeY
end

function drawer:getPaletteColor(index)
    checkArg(1, index, "number")

    if not self.palette then return 0 end
    return self.palette[index]
end

function drawer:setPaletteColor(index, color)
    checkArg(1, index, "number")
    checkArg(2, color, "number")

    if not self.palette then return false end
    self.palette[index] = color
    return true
end

function drawer:setPalette(palette)
    if self.palette then
        if not palette then
            self.gpu.setDepth(1) --сброс палитры
            self.gpu.setDepth(self.gpu.maxDepth())
        end

        for i = 0, 15 do
            self.palette[i] = palette and palette[i] or self.gpu.getPaletteColor(i)
        end
    end
end

function drawer:setUsingTheDefaultPalette(flag)
    if not self.palette then flag = false end
    self.usingTheDefaultPalette = flag
    self.maxFg = self.usingTheDefaultPalette and 15 or 0xFFFFFF
    if self.softwareBuffer then
        self.softwareBuffer.setUsingTheDefaultPalette(flag)
    end
end

------------------------------------------------------------------------service

function drawer:draw_begin()
    local function applyPalette()
        if self.palette then
            for i = 0, 15 do
                if self.palette[i] ~= self.gpu.getPaletteColor(i) then
                    self.gpu.setPaletteColor(i, self.palette[i])
                end
            end
        end
    end

    self:_begin()
    applyPalette()
    if self.bufferSupport then
        if self.hardwareBuffer then
            self.gpu.setActiveBuffer(self.hardwareBuffer)
            applyPalette()
        else
            self.gpu.setActiveBuffer(0)
        end
    end
end

function drawer:draw_end()
    if self.softwareBuffer then
        self.softwareBuffer.update(self.flushed)
        self.flushed = nil
    end
    if self.hardwareBuffer then
        self.gpu.bitblt()
    end
end

function drawer:destroy()
    if self.hardwareBuffer then
        self.gpu.freeBuffer(self.hardwareBuffer)
    end
end

------------------------------------------------------------------------draw utiles

function drawer:_setColor(bg, fg)
    self.gpu.setBackground(advmath.clamp(bg or 0, 0, self.maxFg), self.usingTheDefaultPalette)
    self.gpu.setForeground(advmath.clamp(fg or 0xFFFFFF, 0, self.maxFg), self.usingTheDefaultPalette)
end



function drawer:copy(x, y, sx, sy, tx, ty)
    if self.softwareBuffer then
        self.softwareBuffer.move(x, y, sx, sy, tx, ty, true)
    end
    self.gpu.copy(x, y, sx, sy, tx, ty)
    return true
end

function drawer:set(x, y, bg, fg, str)
    if self.softwareBuffer then
        self.softwareBuffer.set(x, y, bg or 0, fg or self.maxFg, str)
    else
        self:_setColor(bg, fg)
        self.gpu.set(x, y, str)
    end
    return true
end

function drawer:fill(x, y, sx, sy, bg, fg, char)
    if self.softwareBuffer then
        self.softwareBuffer.fill(x, y, sx, sy, bg or 0, fg or self.maxFg, char or " ")
    else
        self:_setColor(bg, fg)
        self.gpu.fill(x, y, sx, sy, char or " ")
    end
    return true
end

function drawer:clear(bg, fg, char)
    self:fill(1, 1, self.sizeX, self.sizeY, bg, fg, char)
    return true
end


return drawer