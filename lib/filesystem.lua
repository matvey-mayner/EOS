local filesystem = {}

function filesystem.segments(path)
    local parts = {}
    for part in path:gmatch("[^\\/]+") do
        local current, up = part:find("^%.?%.$")
        if current then
            if up == 2 then
                table.remove(parts)
            end
        else
            table.insert(parts, part)
        end
    end
    return parts
end

function filesystem.concat(...)
    local set = table.pack(...)
    for index, value in ipairs(set) do
      checkArg(index, value, "string")
    end
    return filesystem.canonical(table.concat(set, "/"))
end

function filesystem.xconcat(...) --работает как concat но пути начинаюшиеся со / НЕ обрабатываються как отновительные а откидывают путь в начало
    local set = table.pack(...)
    for index, value in ipairs(set) do
        checkArg(index, value, "string")
    end
    for index, value in ipairs(set) do
        if value:sub(1, 1) == "/" and index > 1 then
            local newset = {}
            for i = index, #set do
                table.insert(newset, set[i])
            end
            return filesystem.xconcat(table.unpack(newset))
        end
    end
    return filesystem.canonical(table.concat(set, "/"))
end

function filesystem.sconcat(main, ...) --работает так же как concat но если итоговый путь не указывает на целевой обьект первого путя то вернет false
    main = filesystem.canonical(main) .. "/"
    local path = filesystem.concat(main, ...) .. "/"
    if unicode.sub(path, 1, unicode.len(main)) == main then
        return path
    end
    return false
end

function filesystem.canonical(path)
    local result = table.concat(filesystem.segments(path), "/")
    if unicode.sub(path, 1, 1) == "/" then
        return "/" .. result
    else
        return result
    end
end

function filesystem.path(path)
    local parts = filesystem.segments(path)
    local result = table.concat(parts, "/", 1, #parts - 1) .. "/"
    if unicode.sub(path, 1, 1) == "/" and unicode.sub(result, 1, 1) ~= "/" then
        return filesystem.canonical("/" .. result)
    else
        return filesystem.canonical(result)
    end
end
  
function filesystem.name(path)
    checkArg(1, path, "string")
    local parts = filesystem.segments(path)
    return parts[#parts]
end

function filesystem.extension(path)
	local data = path:match("[^%/]+(%.[^%/]+)%/?$")
    if data then
        local str = unicode.sub(data, 2, unicode.len(data))
        if #str then
            return str
        end
    end
    return nil
end

function filesystem.hideExtension(path)
    if filesystem.name(path):sub(1, 1) == "." and not string.find(filesystem.name(path):sub(2, 2), "%.") then
        return path
    end
	return path:match("(.+)%..+") or path
end

------------------------------------------------------------------------------------

filesystem.mountList = {}

function filesystem.mount(proxy, path)
	if type(proxy) == "string" then
		local lproxy, err = component.proxy(proxy)
		if not lproxy then
			return nil, err
		end
		proxy = lproxy
	end

    path = filesystem.canonical(path)
	if path:sub(#path, #path) ~= "/" then path = path .. "/" end
    for i, v in ipairs(filesystem.mountList) do
        if v[2] == path then
            return nil, "another filesystem is already mounted here"
        end
    end
    table.insert(filesystem.mountList, {proxy, path})
	table.sort(filesystem.mountList, function(a, b)
		return unicode.len(a[2]) > unicode.len(b[2])
	end)
	return true
end

function filesystem.umount(path)
    path = filesystem.canonical(path)
	if path:sub(#path, #path) ~= "/" then path = path .. "/" end
    for i, v in ipairs(filesystem.mountList) do
        if v[2] == path then
            table.remove(filesystem.mountList, i)
            return true
        end
    end
    return false
end

function filesystem.get(path)
    path = filesystem.canonical(path)
	if path:sub(#path, #path) ~= "/" then path = path .. "/" end
    for i = 1, #filesystem.mountList do
        if unicode.sub(path, 1, unicode.len(filesystem.mountList[i][2])) == (filesystem.mountList[i][2]) then
            return filesystem.mountList[i][1], unicode.sub(path, unicode.len(filesystem.mountList[i][2]) + 1, -1)
        end
    end

	if filesystem.mountList[1] then
		return filesystem.mountList[1][1], filesystem.mountList[1][2]
	end
end

--[[
function filesystem.get(path)
	path = filesystem.canonical(path)
	for i = 1, #filesystem.mountList do
		if path:sub(1, unicode.len(filesystem.mountList[i][2])) == filesystem.mountList[i][2] then
			return filesystem.mountList[i][1], unicode.sub(path, filesystem.mountList[i][2]:len() + 1, -1)
		end
	end
end
]]

function filesystem.exists(path)
	local proxy, proxyPath = filesystem.get(path)
	return proxy.exists(proxyPath)
end

function filesystem.size(path)
	local proxy, proxyPath = filesystem.get(path)
	return proxy.size(proxyPath)
end

function filesystem.isDirectory(path)
	for i, v in ipairs(filesystem.mountList) do
		if v[2] == filesystem.canonical(path) then
			return true
		end
	end

	local proxy, proxyPath = filesystem.get(path)
	return proxy.isDirectory(proxyPath)
end

function filesystem.makeDirectory(path)
	local proxy, proxyPath = filesystem.get(path)
	return proxy.makeDirectory(proxyPath)
end

function filesystem.lastModified(path)
	local proxy, proxyPath = filesystem.get(path)
	return proxy.lastModified(proxyPath)
end

function filesystem.remove(path)
	local proxy, proxyPath = filesystem.get(path)
	return proxy.remove(proxyPath)
end

function filesystem.list(path)
	local proxy, proxyPath = filesystem.get(path)
	local tbl = proxy.list(proxyPath)

	if tbl then
		tbl.n = nil
		for i = 1, #filesystem.mountList do
			if filesystem.canonical(path) == filesystem.path(filesystem.mountList[i][2]) then
				table.insert(tbl, filesystem.name(filesystem.mountList[i][2]))
			end
		end
		table.sort(tbl)
		return tbl
	else
		return {}
	end
end

function filesystem.rename(fromPath, toPath)
	fromPath = filesystem.canonical(fromPath)
	toPath = filesystem.canonical(toPath)
	if fromPath == toPath then return end

	local fromProxy, fromProxyPath = filesystem.get(fromPath)
	local toProxy, toProxyPath = filesystem.get(toPath)

	-- If it's the same filesystem component
	if fromProxy.address == toProxy.address then
		return fromProxy.rename(fromProxyPath, toProxyPath)
	else
		-- Copy files to destination
		filesystem.copy(fromPath, toPath)
		-- Remove original files
		filesystem.remove(fromPath)
	end
end

function filesystem.open(path, mode)
	if mode then
		mode = mode:sub(1, 1):lower()
		if mode == "w" or mode == "a" then
			filesystem.makeDirectory(filesystem.path(path))
		end
	end

	local proxy, proxyPath = filesystem.get(path)
	local result, reason = proxy.open(proxyPath, mode)
	if result then
		local handle = { --а нам он и нафиг не нужен цей файл buffer...
            read = function(...) return proxy.read(result, ...) end,
            write = function(...) return proxy.write(result, ...) end,
            close = function(...) return proxy.close(result, ...) end,
            seek = function(...) return proxy.seek(result, ...) end,
			readAll = function()
				local buffer = ""
				repeat
					local data = proxy.read(result, math.huge)
					buffer = buffer .. (data or "")
				until not data
				return buffer
			end,
            handle = result,
			proxy = proxy,
		}

        return handle
	end
    return nil, reason
end

function filesystem.copy(fromPath, toPath)
	fromPath = filesystem.canonical(fromPath)
	toPath = filesystem.canonical(toPath)
	if fromPath == toPath then return end
	local function copyRecursively(fromPath, toPath)
		if filesystem.isDirectory(fromPath) then
			filesystem.makeDirectory(toPath)

			local list = filesystem.list(fromPath)
			for i = 1, #list do
				copyRecursively(fromPath .. "/" .. list[i], toPath .. "/" .. list[i])
			end
		else
			local fromHandle = filesystem.open(fromPath, "rb")
			if fromHandle then
				local toHandle = filesystem.open(toPath, "wb")
				if toHandle then
					while true do
						local chunk = fromHandle.read(math.huge)
						if chunk then
							if not toHandle.write(chunk) then
								break
							end
						else
							toHandle.close()
							fromHandle.close()

							break
						end
					end
				end
			end
		end
	end

	copyRecursively(fromPath, toPath)
end

assert(filesystem.mount(bootaddress, "/"))
assert(filesystem.mount(computer.tmpAddress(), "/tmp"))

------------------------------------------------------------------------------------

function filesystem.readFile(path)
    checkArg(1, path, "string")

    if not filesystem.exists(path) then return nil, "file not found" end
    if filesystem.isDirectory(path) then return nil, "is directory" end
    
	local file, err = filesystem.open(path, "rb")
	if not file then return nil, err end
	local buffer = file.readAll()
    file.close()

    return buffer
end

function filesystem.writeFile(path, data)
    checkArg(1, path, "string")
    checkArg(2, data, "string")

	local file, err = filesystem.open(path, "wb")
	if not file then return nil, err end
	local ok = file.write(data)
    file.close()

    return ok
end

return filesystem