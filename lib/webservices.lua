local internet = require("internet")
local programs = require("programs")

local webservices = {}
webservices.startUrl = "https://raw.githubusercontent.com/igorkll/liteOS/main/services/"
--webservices.endUrl = "?token=example"

function webservices.url(name)
    if name:sub(1, 1) == "/" then name = name:sub(2, -1) end
    return (webservices.startUrl or "") .. name .. (webservices.endUrl or "")
end

function webservices.loadData(name)
    return internet.wget(webservices.url(name))
end

function webservices.load(name)
    local data, err = webservices.loadData(name)
    if not data then return nil, err end
    return programs.loadText(data, "web_service=" .. name)
end

function webservices.raw_run(name, ...)
    local code, err = webservices.load(name)
    if not code then return nil, err end
    return code(...)
end

function webservices.run(name, ...)
    return webservices.raw_run(name, {args = {...}})
end

return webservices