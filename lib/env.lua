local env = {}

function env.createProgrammEnv(localEnv) --создает env для программы, где _G это будут глобалы а _ENV будет личная таблица окружения
    localEnv = localEnv or {}
    localEnv._G = _G
    setmetatable(localEnv, {__index = _G})
    return localEnv
end

return env