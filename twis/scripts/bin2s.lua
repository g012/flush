#!/usr/bin/env lua

if #arg < 2 then
    print('bin2s - convert binary files to assembly')
    print('usage: bin2s foo.bin bar.bin <out>')
    os.exit(true)
end

local ioopen = function(fn, m)
    local f,e = io.open(fn, m)
    if f == nil then print(e) os.exit(false) end
    return f
end
local basename = function(s)
    return string.gsub(string.match(s, ".-([^\\/]-)%.?[^%.\\/]*$"), '%.', '_')
end

local f = {}
for i=1,#arg-1 do
    table.insert(f, ioopen(arg[i], "rb"))
end

local bname = arg[#arg]
local fs = ioopen(bname .. '.s', "wb") -- unix fileformat everywhere
local fh = ioopen(bname .. '.h', "wb")

fs:write([[/* Generated by BIN2S [Lua] - please don't edit directly */
    .section .rodata
]])
fh:write([[#pragma once

]])
for k,fb in ipairs(f) do
    local n = basename(arg[k])
    fs:write(string.format([[
    .align 2
    .global %s
%s:
]], n, n))
    local linec = 16
    while true do
        local d = fb:read(linec)
        if not d then break end
        local sa = {}
        for b in string.gmatch(d, '.') do
            table.insert(sa, string.format("0x%02X", string.byte(b)))
        end
        fs:write(string.format("    .byte %s\n", table.concat(sa, ',')));
    end
    local sz = fb:seek()
    fh:write("#define " .. n .. "_size " .. sz, "\n")
    fh:write("extern u8 " .. n .. "[];\n")
    fb:close()
end

fs:close()
fh:close()
