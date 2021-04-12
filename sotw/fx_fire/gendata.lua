#!/usr/bin/env lua

function rgb(r,g,b)
    local sr,sl = bit32.rshift, bit32.lshift
    local c = bit32.bor(sr(r,3), sl(sr(g,3),5), sl(sr(b,3),10))
    return bit32.band(c,255), sr(c,8)
end

function readPalette(f)
    local t = {}
    for line in io.lines(f) do
        local r,g,b = line:match('#(%x%x)(%x%x)(%x%x)')
        local lo,hi = rgb(tonumber(r,16), tonumber(g,16), tonumber(b,16))
        t[#t+1]=lo t[#t+1]=hi
    end
    return t
end

function asBin(t)
    return string.char(table.unpack(t))
end

for k,v in ipairs{'palette1.txt', 'palette2.txt'} do
    f = io.open('data/fxfr_pal' .. k .. '.bin', 'wb')
    f:write(asBin(readPalette(v)))
    f:close()
end
